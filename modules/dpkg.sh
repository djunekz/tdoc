#!/usr/bin/env bash
# ==============================
# TDOC — Module: dpkg Health Scan
# ==============================
# Scans for common dpkg/apt database problems:
#   - error processing package X (--configure)
#   - half-installed / half-configured packages
#   - sub-process /usr/bin/dpkg returned error code (1)
#   - warning: files list file missing
#   - reinst-required / ghost packages
#   - database status corrupt / missing
#   - stale lock file after crash
#   - broken / unmet dependencies
#   - file conflicts between packages
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
DPKG_STATE_DIR="${PREFIX}/var/lib/dpkg"
DPKG_LOCK="${PREFIX}/var/lib/dpkg/lock"
DPKG_LOCK_FRONTEND="${PREFIX}/var/cache/apt/archives/lock"
DPKG_STATUS="${PREFIX}/var/lib/dpkg/status"
DPKG_INFO_DIR="${PREFIX}/var/lib/dpkg/info"

# ── Helpers ────────────────────────────────────────────────────────────────────

_dpkg_write_state() {
  local key="$1" value="$2"
  # Remove any existing entry for this key first
  grep -v "^${key}=" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
  mv "${STATE_FILE}.tmp" "$STATE_FILE" 2>/dev/null || true
  echo "${key}=${value}" >> "$STATE_FILE"
}

check_dpkg_lock() {
  local stale=false

  for lockfile in "$DPKG_LOCK" "$DPKG_LOCK_FRONTEND"; do
    [[ -f "$lockfile" ]] || continue
    if ! fuser "$lockfile" >/dev/null 2>&1; then
      stale=true
      break
    fi
  done

  if $stale; then
    _dpkg_write_state "DpkgLock" "STALE"
    print_err "$(t L_DPKG_SCAN_LOCK)"
  else
    _dpkg_write_state "DpkgLock" "OK"
    print_ok "$(t L_DPKG_SCAN_LOCK)"
  fi
}

check_dpkg_status_db() {
  if [[ ! -f "$DPKG_STATUS" ]]; then
    _dpkg_write_state "DpkgStatusDB" "MISSING"
    print_err "$(t L_DPKG_SCAN_STATUS_DB)"
    return
  fi
  if ! grep -q "^Package:" "$DPKG_STATUS" 2>/dev/null; then
    _dpkg_write_state "DpkgStatusDB" "CORRUPT"
    print_err "$(t L_DPKG_SCAN_STATUS_DB)"
    return
  fi
  _dpkg_write_state "DpkgStatusDB" "OK"
  print_ok "$(t L_DPKG_SCAN_STATUS_DB)"
}

check_dpkg_half_installed() {
  if [[ ! -f "$DPKG_STATUS" ]]; then
    _dpkg_write_state "DpkgHalfInstalled" "SKIPPED"
    return
  fi

  local half_pkgs
  half_pkgs=$(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*half-installed|^Status:.*half-configured/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  if [[ -n "$half_pkgs" ]]; then
    local count
    count=$(echo "$half_pkgs" | wc -l)
    _dpkg_write_state "DpkgHalfInstalled" "BROKEN:${count}"
    print_err "$(t L_DPKG_SCAN_HALF) ($count)"
    echo "$half_pkgs" | while read -r p; do
      [[ -n "$p" ]] && print_info "  • $p"
    done
  else
    _dpkg_write_state "DpkgHalfInstalled" "OK"
    print_ok "$(t L_DPKG_SCAN_HALF)"
  fi
}

check_dpkg_reinst_required() {
  if [[ ! -f "$DPKG_STATUS" ]]; then
    _dpkg_write_state "DpkgReinstRequired" "SKIPPED"
    return
  fi

  local reinst_pkgs
  reinst_pkgs=$(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*reinst-required/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  if [[ -n "$reinst_pkgs" ]]; then
    local count
    count=$(echo "$reinst_pkgs" | wc -l)
    _dpkg_write_state "DpkgReinstRequired" "BROKEN:${count}"
    print_err "$(t L_DPKG_SCAN_REINST) ($count)"
    echo "$reinst_pkgs" | while read -r p; do
      [[ -n "$p" ]] && print_info "  • $p"
    done
  else
    _dpkg_write_state "DpkgReinstRequired" "OK"
    print_ok "$(t L_DPKG_SCAN_REINST)"
  fi
}

check_dpkg_broken_deps() {
  local broken_out
  broken_out=$(dpkg --audit 2>/dev/null || true)

  if [[ -n "$broken_out" ]]; then
    _dpkg_write_state "DpkgBrokenDeps" "BROKEN"
    print_err "$(t L_DPKG_SCAN_BROKEN_DEPS)"
    echo "$broken_out" | head -10 | while read -r line; do
      [[ -n "$line" ]] && print_info "  $line"
    done
  else
    _dpkg_write_state "DpkgBrokenDeps" "OK"
    print_ok "$(t L_DPKG_SCAN_BROKEN_DEPS)"
  fi
}

check_dpkg_missing_files_list() {
  if [[ ! -d "$DPKG_INFO_DIR" ]]; then
    _dpkg_write_state "DpkgMissingFilesList" "SKIPPED"
    return
  fi

  local missing_list=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if [[ ! -f "${DPKG_INFO_DIR}/${pkg}.list" ]]; then
      missing_list+=("$pkg")
    fi
  done < <(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*installed/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  local count="${#missing_list[@]}"
  if [[ $count -gt 0 ]]; then
    _dpkg_write_state "DpkgMissingFilesList" "BROKEN:${count}"
    print_err "$(t L_DPKG_SCAN_FILES_LIST) ($count)"
    for p in "${missing_list[@]:0:5}"; do
      print_info "  • $p"
    done
    [[ $count -gt 5 ]] && print_info "  ... and $((count - 5)) more"
  else
    _dpkg_write_state "DpkgMissingFilesList" "OK"
    print_ok "$(t L_DPKG_SCAN_FILES_LIST)"
  fi
}

check_dpkg_file_conflicts() {
  local conflicts_found=false

  if [[ -f "$DPKG_STATUS" ]]; then
    local installed_pkgs
    installed_pkgs=$(awk '
      /^Package:/ { pkg = $2 }
      /^Status:.*\binstalled\b/ { print pkg }
    ' "$DPKG_STATUS" 2>/dev/null || true)

    local real_conflicts=""
    local cur_pkg="" cur_conflicts=""
    while IFS= read -r line; do
      case "$line" in
        Package:*)
          cur_pkg="${line#Package: }"
          cur_conflicts=""
          ;;
        Status:*installed*)
          : # pkg stays current
          ;;
        Conflicts:*)
          cur_conflicts="${line#Conflicts: }"
          ;;
        "")
          if [[ -n "$cur_pkg" && -n "$cur_conflicts" ]]; then
            if echo "$installed_pkgs" | grep -qx "$cur_pkg"; then
              local IFS_ORIG="$IFS"; IFS=','
              for target in $cur_conflicts; do
                local tname
                tname=$(echo "$target" | sed 's/([^)]*)//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
                [[ -z "$tname" ]] && continue
                if echo "$installed_pkgs" | grep -qx "$tname"; then
                  real_conflicts+="$cur_pkg conflicts with installed $tname\n"
                fi
              done
              IFS="$IFS_ORIG"
            fi
          fi
          cur_pkg=""; cur_conflicts=""
          ;;
      esac
    done < "$DPKG_STATUS"

    if [[ -n "$real_conflicts" ]]; then
      conflicts_found=true
      _dpkg_write_state "DpkgFileConflicts" "BROKEN"
      print_err "$(t L_DPKG_SCAN_CONFLICTS)"
      echo -e "$real_conflicts" | head -5 | while read -r line; do
        [[ -n "$line" ]] && print_info "  $line"
      done
    fi
  fi

  if ! $conflicts_found; then
    _dpkg_write_state "DpkgFileConflicts" "OK"
    print_ok "$(t L_DPKG_SCAN_CONFLICTS)"
  fi
}

check_dpkg() {
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📦 $(t L_DPKG_SCAN_HEADER)${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo

  check_dpkg_lock
  check_dpkg_status_db
  check_dpkg_half_installed
  check_dpkg_reinst_required
  check_dpkg_broken_deps
  check_dpkg_missing_files_list
  check_dpkg_file_conflicts

  echo
}
