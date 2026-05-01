#!/usr/bin/env bash
# ==============================
# TDOC — dpkg Fix Handlers
# Handles all dpkg-related repair actions.
# Called by fix.sh, fix_auto.sh, fix_preview.sh
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

DPKG_LOCK="${PREFIX}/var/lib/dpkg/lock"
DPKG_LOCK_FRONTEND="${PREFIX}/var/cache/apt/archives/lock"
DPKG_STATUS="${PREFIX}/var/lib/dpkg/status"
DPKG_STATUS_BAK="${PREFIX}/var/lib/dpkg/status.backup.tdoc"
DPKG_INFO_DIR="${PREFIX}/var/lib/dpkg/info"

fix_DpkgLock() {
  read -rp "$(t L_DPKG_FIX_LOCK_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_LOCK_SKIP)"; skipped_items+=("DpkgLock"); return; }

  local removed=false
  for lockfile in "$DPKG_LOCK" "$DPKG_LOCK_FRONTEND"; do
    if [[ -f "$lockfile" ]]; then
      if fuser "$lockfile" >/dev/null 2>&1; then
        print_warn "$(t L_DPKG_FIX_LOCK_IN_USE): $lockfile"
        print_info "$(t L_DPKG_FIX_LOCK_KILL_HINT)"
      else
        rm -f "$lockfile"
        print_ok "$(t L_DPKG_FIX_LOCK_REMOVED): $lockfile"
        removed=true
      fi
    fi
  done

  if $removed; then
    fixed_items+=("DpkgLock")
    print_info "$(t L_DPKG_FIX_LOCK_NEXT)"
  else
    skipped_items+=("DpkgLock")
  fi
}

auto_fix_DpkgLock() {
  for lockfile in "$DPKG_LOCK" "$DPKG_LOCK_FRONTEND"; do
    if [[ -f "$lockfile" ]]; then
      if fuser "$lockfile" >/dev/null 2>&1; then
        print_warn "$(t L_DPKG_FIX_LOCK_IN_USE): $lockfile"
        skipped+=("DpkgLock"); return
      else
        rm -f "$lockfile"
        print_ok "$(t L_DPKG_FIX_LOCK_REMOVED): $lockfile"
      fi
    fi
  done
  fixed+=("DpkgLock")
  print_info "$(t L_DPKG_FIX_LOCK_NEXT)"
}

preview_DpkgLock() {
  echo -e "${GRAY}  → rm -f $DPKG_LOCK${RESET}"
  echo -e "${GRAY}  → rm -f $DPKG_LOCK_FRONTEND${RESET}"
}

fix_DpkgStatusDB() {
  local status_val
  status_val=$(grep "^DpkgStatusDB=" "${PREFIX}/var/lib/tdoc/state.env" | cut -d= -f2)

  read -rp "$(t L_DPKG_FIX_STATUS_DB_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_STATUS_DB_SKIP)"; skipped_items+=("DpkgStatusDB"); return; }

  if [[ "$status_val" == "MISSING" ]]; then
    if [[ -d "$DPKG_INFO_DIR" ]]; then
      spinner_start "$(t L_DPKG_FIX_STATUS_DB_REBUILD)..."
      : > "$DPKG_STATUS"
      for list_file in "$DPKG_INFO_DIR"/*.list; do
        [[ -f "$list_file" ]] || continue
        local pkg_name
        pkg_name=$(basename "$list_file" .list)
        printf "Package: %s\nStatus: install ok installed\nVersion: (unknown)\nDescription: (recovered by tdoc)\n\n" "$pkg_name" >> "$DPKG_STATUS"
      done
      spinner_stop
      print_ok "$(t L_DPKG_FIX_STATUS_DB_REBUILT)"
      fixed_items+=("DpkgStatusDB")
    else
      spinner_stop
      print_err "$(t L_DPKG_FIX_STATUS_DB_CANT_REBUILD)"
      print_info "$(t L_DPKG_FIX_STATUS_DB_MANUAL)"
      skipped_items+=("DpkgStatusDB")
    fi
  elif [[ "$status_val" == "CORRUPT" ]]; then
    spinner_start "$(t L_DPKG_FIX_STATUS_DB_REPAIR)..."
    if [[ -f "${DPKG_STATUS}-old" ]]; then
      cp "${DPKG_STATUS}-old" "$DPKG_STATUS_BAK"
      cp "${DPKG_STATUS}-old" "$DPKG_STATUS"
      spinner_stop
      print_ok "$(t L_DPKG_FIX_STATUS_DB_RESTORED_BACKUP)"
      dpkg --configure -a 2>/dev/null || true
      fixed_items+=("DpkgStatusDB")
    else
      spinner_stop
      print_warn "$(t L_DPKG_FIX_STATUS_DB_NO_BACKUP)"
      print_info "$(t L_DPKG_FIX_STATUS_DB_MANUAL)"
      skipped_items+=("DpkgStatusDB")
    fi
  fi
}

auto_fix_DpkgStatusDB() {
  local status_val
  status_val=$(grep "^DpkgStatusDB=" "${PREFIX}/var/lib/tdoc/state.env" | cut -d= -f2)
  spinner_start "$(t L_DPKG_FIX_STATUS_DB_REPAIR)..."
  if [[ "$status_val" == "MISSING" && -d "$DPKG_INFO_DIR" ]]; then
    : > "$DPKG_STATUS"
    for list_file in "$DPKG_INFO_DIR"/*.list; do
      [[ -f "$list_file" ]] || continue
      local pkg_name; pkg_name=$(basename "$list_file" .list)
      printf "Package: %s\nStatus: install ok installed\nVersion: (unknown)\nDescription: (recovered by tdoc)\n\n" "$pkg_name" >> "$DPKG_STATUS"
    done
    spinner_stop; print_ok "$(t L_DPKG_FIX_STATUS_DB_REBUILT)"; fixed+=("DpkgStatusDB")
  elif [[ "$status_val" == "CORRUPT" && -f "${DPKG_STATUS}-old" ]]; then
    cp "${DPKG_STATUS}-old" "$DPKG_STATUS"
    spinner_stop; print_ok "$(t L_DPKG_FIX_STATUS_DB_RESTORED_BACKUP)"
    dpkg --configure -a 2>/dev/null || true
    fixed+=("DpkgStatusDB")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_STATUS_DB_NO_BACKUP)"
    print_info "$(t L_DPKG_FIX_STATUS_DB_MANUAL)"; skipped+=("DpkgStatusDB")
  fi
}

preview_DpkgStatusDB() {
  echo -e "${GRAY}  → cp \${PREFIX}/var/lib/dpkg/status-old \${PREFIX}/var/lib/dpkg/status${RESET}"
  echo -e "${GRAY}  → dpkg --configure -a${RESET}"
}

fix_DpkgHalfInstalled() {
  read -rp "$(t L_DPKG_FIX_HALF_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_HALF_SKIP)"; skipped_items+=("DpkgHalfInstalled"); return; }

  spinner_start "dpkg --configure -a..."
  if dpkg --configure -a 2>/dev/null; then
    spinner_stop
    print_ok "$(t L_DPKG_FIX_HALF_CONFIGURED)"
    apt-get install -f -y 2>/dev/null || true
    fixed_items+=("DpkgHalfInstalled")
  else
    spinner_stop
    print_warn "$(t L_DPKG_FIX_HALF_PARTIAL)"
    print_info "$(t L_DPKG_FIX_HALF_HINT)"
    skipped_items+=("DpkgHalfInstalled")
  fi
}

auto_fix_DpkgHalfInstalled() {
  spinner_start "dpkg --configure -a..."
  if dpkg --configure -a 2>/dev/null; then
    spinner_stop; print_ok "$(t L_DPKG_FIX_HALF_CONFIGURED)"
    apt-get install -f -y 2>/dev/null || true
    fixed+=("DpkgHalfInstalled")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_HALF_PARTIAL)"
    print_info "$(t L_DPKG_FIX_HALF_HINT)"; skipped+=("DpkgHalfInstalled")
  fi
}

preview_DpkgHalfInstalled() {
  echo -e "${GRAY}  → dpkg --configure -a${RESET}"
  echo -e "${GRAY}  → apt-get install -f -y${RESET}"
}

fix_DpkgReinstRequired() {
  local reinst_pkgs
  reinst_pkgs=$(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*reinst-required/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  if [[ -z "$reinst_pkgs" ]]; then
    print_ok "$(t L_DPKG_FIX_REINST_NONE)"
    fixed_items+=("DpkgReinstRequired"); return
  fi

  echo "$reinst_pkgs" | while read -r p; do
    [[ -n "$p" ]] && print_info "  • $p"
  done

  read -rp "$(t L_DPKG_FIX_REINST_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_REINST_SKIP)"; skipped_items+=("DpkgReinstRequired"); return; }

  local all_ok=true
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    spinner_start "Reinstalling $pkg..."
    if pkg reinstall -y "$pkg" 2>/dev/null; then
      spinner_stop; print_ok "$pkg $(t L_DPKG_FIX_REINST_OK)"
    else
      spinner_stop; print_warn "$pkg $(t L_DPKG_FIX_REINST_FAIL)"
      all_ok=false
    fi
  done <<< "$reinst_pkgs"

  if $all_ok; then
    fixed_items+=("DpkgReinstRequired")
  else
    skipped_items+=("DpkgReinstRequired")
    print_info "$(t L_DPKG_FIX_REINST_MANUAL)"
  fi
}

auto_fix_DpkgReinstRequired() {
  local reinst_pkgs
  reinst_pkgs=$(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*reinst-required/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)
  [[ -z "$reinst_pkgs" ]] && { fixed+=("DpkgReinstRequired"); return; }

  local all_ok=true
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    spinner_start "Reinstalling $pkg..."
    if pkg reinstall -y "$pkg" 2>/dev/null; then
      spinner_stop; print_ok "$pkg $(t L_DPKG_FIX_REINST_OK)"
    else
      spinner_stop; print_warn "$pkg $(t L_DPKG_FIX_REINST_FAIL)"
      all_ok=false
    fi
  done <<< "$reinst_pkgs"

  $all_ok && fixed+=("DpkgReinstRequired") || { skipped+=("DpkgReinstRequired"); print_info "$(t L_DPKG_FIX_REINST_MANUAL)"; }
}

preview_DpkgReinstRequired() {
  local reinst_pkgs
  reinst_pkgs=$(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*reinst-required/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && echo -e "${GRAY}  → pkg reinstall -y $pkg${RESET}"
  done <<< "$reinst_pkgs"
}

fix_DpkgBrokenDeps() {
  read -rp "$(t L_DPKG_FIX_BROKEN_DEPS_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_BROKEN_DEPS_SKIP)"; skipped_items+=("DpkgBrokenDeps"); return; }

  spinner_start "apt-get install -f -y..."
  if apt-get install -f -y 2>/dev/null; then
    spinner_stop; print_ok "$(t L_DPKG_FIX_BROKEN_DEPS_OK)"
    fixed_items+=("DpkgBrokenDeps")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_BROKEN_DEPS_FAIL)"
    print_info "$(t L_DPKG_FIX_BROKEN_DEPS_HINT)"
    skipped_items+=("DpkgBrokenDeps")
  fi
}

auto_fix_DpkgBrokenDeps() {
  spinner_start "apt-get install -f -y..."
  if apt-get install -f -y 2>/dev/null; then
    spinner_stop; print_ok "$(t L_DPKG_FIX_BROKEN_DEPS_OK)"; fixed+=("DpkgBrokenDeps")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_BROKEN_DEPS_FAIL)"
    print_info "$(t L_DPKG_FIX_BROKEN_DEPS_HINT)"; skipped+=("DpkgBrokenDeps")
  fi
}

preview_DpkgBrokenDeps() {
  echo -e "${GRAY}  → apt-get install -f -y${RESET}"
  echo -e "${GRAY}  → dpkg --configure -a${RESET}"
}

fix_DpkgMissingFilesList() {
  local missing_list=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    [[ ! -f "${DPKG_INFO_DIR}/${pkg}.list" ]] && missing_list+=("$pkg")
  done < <(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*installed/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  local count="${#missing_list[@]}"
  if [[ $count -eq 0 ]]; then
    print_ok "$(t L_DPKG_FIX_FILES_LIST_NONE)"
    fixed_items+=("DpkgMissingFilesList"); return
  fi

  print_info "$(t L_DPKG_FIX_FILES_LIST_FOUND): $count"
  read -rp "$(t L_DPKG_FIX_FILES_LIST_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_FILES_LIST_SKIP)"; skipped_items+=("DpkgMissingFilesList"); return; }

  local repaired=0
  for pkg in "${missing_list[@]}"; do
    spinner_start "Reinstalling $pkg..."
    if pkg reinstall -y "$pkg" 2>/dev/null; then
      spinner_stop; print_ok "$pkg"
      repaired=$((repaired+1))
    else
      spinner_stop; print_warn "$pkg $(t L_DPKG_FIX_FILES_LIST_FAIL)"
      touch "${DPKG_INFO_DIR}/${pkg}.list" 2>/dev/null || true
    fi
  done

  print_info "$(t L_DPKG_FIX_FILES_LIST_REPAIRED): $repaired / $count"
  fixed_items+=("DpkgMissingFilesList")
}

auto_fix_DpkgMissingFilesList() {
  local missing_list=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    [[ ! -f "${DPKG_INFO_DIR}/${pkg}.list" ]] && missing_list+=("$pkg")
  done < <(awk '
    /^Package:/ { pkg = $2 }
    /^Status:.*installed/ { print pkg }
  ' "$DPKG_STATUS" 2>/dev/null || true)

  for pkg in "${missing_list[@]}"; do
    spinner_start "Reinstalling $pkg..."
    if pkg reinstall -y "$pkg" 2>/dev/null; then
      spinner_stop; print_ok "$pkg"
    else
      spinner_stop; touch "${DPKG_INFO_DIR}/${pkg}.list" 2>/dev/null || true
      print_warn "$pkg (stub created)"
    fi
  done
  fixed+=("DpkgMissingFilesList")
}

preview_DpkgMissingFilesList() {
  echo -e "${GRAY}  → pkg reinstall <each package with missing .list>${RESET}"
  echo -e "${GRAY}  → touch \${PREFIX}/var/lib/dpkg/info/<pkg>.list  (stub fallback)${RESET}"
}

fix_DpkgFileConflicts() {
  read -rp "$(t L_DPKG_FIX_CONFLICTS_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_DPKG_FIX_CONFLICTS_SKIP)"; skipped_items+=("DpkgFileConflicts"); return; }

  spinner_start "apt-get install -f -y..."
  if apt-get install -f -y 2>/dev/null; then
    spinner_stop; print_ok "$(t L_DPKG_FIX_CONFLICTS_OK)"
    fixed_items+=("DpkgFileConflicts")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_CONFLICTS_FAIL)"
    print_info "$(t L_DPKG_FIX_CONFLICTS_HINT)"
    skipped_items+=("DpkgFileConflicts")
  fi
}

auto_fix_DpkgFileConflicts() {
  spinner_start "apt-get install -f -y..."
  if apt-get install -f -y 2>/dev/null; then
    spinner_stop; print_ok "$(t L_DPKG_FIX_CONFLICTS_OK)"; fixed+=("DpkgFileConflicts")
  else
    spinner_stop; print_warn "$(t L_DPKG_FIX_CONFLICTS_FAIL)"
    print_info "$(t L_DPKG_FIX_CONFLICTS_HINT)"; skipped+=("DpkgFileConflicts")
  fi
}

preview_DpkgFileConflicts() {
  echo -e "${GRAY}  → apt-get install -f -y${RESET}"
  echo -e "${GRAY}  → dpkg -i --force-overwrite <conflicting package>  (manual)${RESET}"
}
