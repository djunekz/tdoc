#!/usr/bin/env bash
# TDOC — Fix Mode AUTO

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/fix_dpkg.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
print_header "🤖 $(t L_FIX_AUTO_HEADER)"
echo

if [[ ! -f "$STATE_FILE" ]]; then
  print_err "$(t L_FIX_NO_STATE)"; print_info "$(t L_FIX_RUN_SCAN)"; exit 1
fi

report_init
fixed=(); skipped=()

auto_fix_Storage() {
  spinner_start "Storage..."
  if termux-setup-storage 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_STORAGE_OK)"; fixed+=("Storage")
  else
    spinner_stop; print_warn "$(t L_FIX_STORAGE_FAIL)"
    print_info "$(t L_FIX_STORAGE_MANUAL)"; skipped+=("Storage")
  fi
}

auto_fix_Repository() {
  print_warn "$(t L_FIX_REPO_WARN)"; print_info "$(t L_FIX_REPO_HINT)"; skipped+=("Repository")
}

auto_fix_Python() {
  spinner_start "Python..."
  if pkg reinstall -y python 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_PYTHON_OK)"; fixed+=("Python")
  else
    spinner_stop; print_err "$(t L_FIX_PYTHON_FAIL)"
    print_info "$(t L_FIX_PYTHON_HINT)"; skipped+=("Python")
  fi
}

auto_fix_Git() {
  spinner_start "Git..."
  if pkg install -y git 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_GIT_OK)"; fixed+=("Git")
  else
    spinner_stop; print_err "$(t L_FIX_GIT_FAIL)"
    print_info "$(t L_FIX_GIT_HINT)"; skipped+=("Git")
  fi
}

auto_fix_NodeJS() {
  spinner_start "NodeJS..."
  if pkg install -y nodejs 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_NODEJS_OK)"; fixed+=("NodeJS")
  else
    spinner_stop; print_err "$(t L_FIX_NODEJS_FAIL)"; skipped+=("NodeJS")
  fi
}

auto_fix_TermuxVersion() {
  print_info "$(t L_FIX_TERMUX_INFO)"; print_info "$(t L_FIX_TERMUX_HINT)"; skipped+=("TermuxVersion")
}

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue
  func="auto_fix_$key"
  echo; echo -e "${CYAN}AUTO:${RESET} $key (${RED}$value${RESET})"
  if declare -f "$func" >/dev/null; then "$func"
  else print_skip "$key $(t L_FIX_NO_HANDLER)"; skipped+=("$key"); fi
done < "$STATE_FILE"

if [[ ${#skipped[@]} -gt 0 ]]; then
  report_append_manual "${fixed[@]+"${fixed[@]}"}" --skipped "${skipped[@]+"${skipped[@]}"}"
else
  report_append_auto "${fixed[@]+"${fixed[@]}"}"
fi

echo; print_ok "$(t L_FIX_DONE)"
print_info "$(t L_FIX_REPORT_SAVED): ~/.tdoc/report.json"
print_info "$(t L_FIX_RUN_STATUS)"
