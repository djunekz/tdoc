#!/usr/bin/env bash
# TDOC — Fix Mode Manual

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/fix_dpkg.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
print_header "🛠 $(t L_FIX_HEADER)"
echo

if [[ ! -f "$STATE_FILE" ]]; then
  print_err "$(t L_FIX_NO_STATE)"; print_info "$(t L_FIX_RUN_SCAN)"; exit 1
fi

report_init
fixed_items=()
skipped_items=()

fix_Storage() {
  read -rp "$(t L_FIX_STORAGE_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_FIX_STORAGE_SKIP)"; skipped_items+=("Storage"); return; }
  if termux-setup-storage 2>/dev/null; then
    print_ok "$(t L_FIX_STORAGE_OK)"; fixed_items+=("Storage")
  else
    print_warn "$(t L_FIX_STORAGE_FAIL)"; skipped_items+=("Storage")
  fi
}

fix_Repository() {
  print_warn "$(t L_FIX_REPO_WARN)"
  print_info "$(t L_FIX_REPO_HINT)"
  skipped_items+=("Repository")
}

fix_NodeJS() {
  read -rp "$(t L_FIX_NODEJS_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_FIX_NODEJS_SKIP)"; skipped_items+=("NodeJS"); return; }
  spinner_start "NodeJS..."
  if pkg install -y nodejs 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_NODEJS_OK)"; fixed_items+=("NodeJS")
  else
    spinner_stop; print_err "$(t L_FIX_NODEJS_FAIL)"; skipped_items+=("NodeJS")
  fi
}

fix_Python() {
  read -rp "$(t L_FIX_PYTHON_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_FIX_PYTHON_SKIP)"; skipped_items+=("Python"); return; }
  spinner_start "Python..."
  if pkg reinstall -y python 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_PYTHON_OK)"; fixed_items+=("Python")
  else
    spinner_stop; print_err "$(t L_FIX_PYTHON_FAIL)"; print_info "$(t L_FIX_PYTHON_HINT)"; skipped_items+=("Python")
  fi
}

fix_Git() {
  read -rp "$(t L_FIX_GIT_PROMPT) $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]] || { print_skip "$(t L_FIX_GIT_SKIP)"; skipped_items+=("Git"); return; }
  spinner_start "Git..."
  if pkg install -y git 2>/dev/null; then
    spinner_stop; print_ok "$(t L_FIX_GIT_OK)"; fixed_items+=("Git")
  else
    spinner_stop; print_err "$(t L_FIX_GIT_FAIL)"; print_info "$(t L_FIX_GIT_HINT)"; skipped_items+=("Git")
  fi
}

fix_TermuxVersion() {
  print_info "$(t L_FIX_TERMUX_INFO)"
  print_info "$(t L_FIX_TERMUX_HINT)"
  skipped_items+=("TermuxVersion")
}

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue
  handler="fix_$key"
  echo; print_info "$(t L_FIX_ISSUE): $key (${RED}${value}${RESET})"
  if declare -f "$handler" >/dev/null; then "$handler"
  elif declare -f "fix_Dpkg${key#Dpkg}" >/dev/null 2>&1; then "fix_Dpkg${key#Dpkg}"
  else print_skip "$(t L_FIX_NO_HANDLER) $key"; skipped_items+=("$key"); fi
done < "$STATE_FILE"

report_append_manual "${fixed_items[@]+"${fixed_items[@]}"}" --skipped "${skipped_items[@]+"${skipped_items[@]}"}"

echo; print_ok "$(t L_FIX_DONE)"; print_info "$(t L_FIX_RUN_STATUS)"
