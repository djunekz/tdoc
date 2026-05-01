#!/usr/bin/env bash
# ==============================
# TDOC — diagnose
# Match a raw error message/symptom to a known issue,
# explain it, and offer to fix it.
#
# Usage:
#   tdoc diagnose "E: dpkg was interrupted"
#   tdoc diagnose "bash: python3: command not found"
#   tdoc diagnose
# ==============================

set -o nounset
set -o pipefail

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/ai_explain.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"


_diag_header() {
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🩺 $(t L_DIAG_HEADER)${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

_diag_match() {
  local input_lower="$1"

  if echo "$input_lower" | grep -qE \
    "dpkg was interrupted|dpkg.*interrupted|you must manually run.*dpkg|run.*dpkg.*--configure"; then
    echo "DpkgHalfInstalled"; return
  fi

  if echo "$input_lower" | grep -qE \
    "sub-process.*dpkg.*returned error|sub-process.*usr/bin/dpkg|dpkg returned error code"; then
    echo "DpkgHalfInstalled"; return
  fi

  if echo "$input_lower" | grep -qE \
    "unable to lock|could not get lock|lock.*var/lib/dpkg|lock.*apt/lists|another process.*using|waiting for lock"; then
    echo "DpkgLock"; return
  fi

  if echo "$input_lower" | grep -qE \
    "half-installed|half-configured|half installed|half configured"; then
    echo "DpkgHalfInstalled"; return
  fi

  if echo "$input_lower" | grep -qE \
    "reinst-required|reinstallation required|ghost package|must be reinstalled"; then
    echo "DpkgReinstRequired"; return
  fi

  if echo "$input_lower" | grep -qE \
    "warning.*files list.*missing|files list file.*for package|dpkg.*info.*list"; then
    echo "DpkgMissingFilesList"; return
  fi

  if echo "$input_lower" | grep -qE \
    "dpkg.*status.*corrupt|status.*database.*corrupt|status file.*corrupted|dpkg.*status.*missing|cannot open.*dpkg/status"; then
    echo "DpkgStatusDB"; return
  fi

  if echo "$input_lower" | grep -qE \
    "unmet dependencies|dependency problems|broken packages|has unmet dep|depends.*but it is not|not going to be installed|apt-get install -f"; then
    echo "DpkgBrokenDeps"; return
  fi

  if echo "$input_lower" | grep -qE \
    "trying to overwrite|conflicts with.*package|dpkg.*overwrite|file.*owned by"; then
    echo "DpkgFileConflicts"; return
  fi

  if echo "$input_lower" | grep -qE \
    "python.*command not found|python3.*not found|no module named|modulenotfounderror|importerror|python.*no such file|pip.*not found|pip3.*not found"; then
    echo "Python"; return
  fi

  if echo "$input_lower" | grep -qE \
    "node.*command not found|nodejs.*not found|npm.*not found|cannot find module|error.*require.*cannot|node.*no such file"; then
    echo "NodeJS"; return
  fi

  if echo "$input_lower" | grep -qE \
    "git.*command not found|git.*not found|git.*not installed|not a git repo|fatal.*not a git|git.*no such file"; then
    echo "Git"; return
  fi

  if echo "$input_lower" | grep -qE \
    "permission denied.*storage|cannot.*write.*storage|storage.*not accessible|termux-setup-storage|/storage/shared.*no such|read-only file system.*storage"; then
    echo "Storage"; return
  fi

  if echo "$input_lower" | grep -qE \
    "failed to fetch|could not resolve.*mirrors|unable to fetch|404.*not found.*repo|repository.*does not have|no release file|gpg error|apt.*update.*fail|pkg update.*fail|sources.list"; then
    echo "Repository"; return
  fi

  if echo "$input_lower" | grep -qE \
    "prefix.*not set|prefix.*not found|termux.*not found|\$prefix.*missing|termux environment|command not found" ; then
    echo "TermuxVersion"; return
  fi

  echo "Unknown"
}

_diag_offer_fix() {
  local issue="$1"

  case "$issue" in
    DpkgLock|DpkgHalfInstalled|DpkgReinstRequired|DpkgBrokenDeps|\
    DpkgMissingFilesList|DpkgFileConflicts|DpkgStatusDB|\
    Python|NodeJS|Git|Storage)
      echo
      read -rp "$(t L_DIAG_OFFER_FIX) $(t L_PROMPT_YN): " ans
      if [[ "$ans" =~ ^[YyTt]$ ]]; then
        mkdir -p "$(dirname "$STATE_FILE")"
        local tmp
        tmp=$(grep -v "^${issue}=" "$STATE_FILE" 2>/dev/null || true)
        echo "$tmp" > "$STATE_FILE"
        echo "${issue}=BROKEN" >> "$STATE_FILE"
        echo
        source "$TDOC_ROOT/core/fix.sh"
      else
        echo
        print_info "$(t L_DIAG_FIX_SKIPPED)"
        print_info "$(t L_DIAG_FIX_HINT): tdoc fix"
      fi
      ;;
    *)
      echo
      print_info "$(t L_DIAG_NO_AUTO_FIX)"
      print_info "$(t L_DIAG_RUN_SCAN): tdoc scan"
      ;;
  esac
}


_diag_run() {
  local raw_input="$*"

  _diag_header

  if [[ -z "$raw_input" ]]; then
    echo -e "${BOLD}$(t L_DIAG_PASTE_PROMPT)${RESET}"
    echo -e "${GRAY}$(t L_DIAG_PASTE_HINT)${RESET}"
    echo
    read -rp "  > " raw_input
    echo
  fi

  if [[ -z "$raw_input" ]]; then
    print_err "$(t L_DIAG_EMPTY_INPUT)"
    exit 1
  fi

  echo -e "${BOLD}$(t L_DIAG_INPUT_LABEL):${RESET}"
  echo -e "  ${GRAY}\"${raw_input}\"${RESET}"
  echo

  local input_lower
  input_lower=$(echo "$raw_input" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

  spinner_start "$(t L_DIAG_ANALYZING)..."
  sleep 0.4
  local issue
  issue=$(_diag_match "$input_lower")
  spinner_stop

  if [[ "$issue" == "Unknown" ]]; then
    echo -e "${YELLOW}⚠ $(t L_DIAG_NO_MATCH)${RESET}"
    echo
    print_info "$(t L_DIAG_NO_MATCH_HINT1)"
    print_info "$(t L_DIAG_NO_MATCH_HINT2): tdoc scan"
    print_info "$(t L_DIAG_NO_MATCH_HINT3): https://github.com/djunekz/tdoc/issues"
    echo
    exit 0
  fi

  echo -e "${GREEN}✔ $(t L_DIAG_MATCHED): ${BOLD}${issue}${RESET}"
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo

  ai_explain "$issue"

  _diag_offer_fix "$issue"

  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

_diag_run "$@"
