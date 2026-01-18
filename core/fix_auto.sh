#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC Fix Mode (AUTO, Compliant)
# ==============================

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/repo.sh"

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$HOME/.tdoc"
REPORT_FILE="$HOME/.tdoc/report.json"

print_header "🤖 TDOC Fix Mode (AUTO)"
echo

report_init
fixed=()
skipped=()

auto_fix_storage() {
  termux-setup-storage
  print_ok "Storage fixed"
  fixed+=("Storage")
}

auto_fix_repository() {
  print_warn "Repository auto-fix requires manual selection"
  print_info "Run manually: termux-change-repo"
  skipped+=("Repository")
}

auto_fix_nodejs() {
  pkg install nodejs
  print_ok "NodeJS installed"
  fixed+=("NodeJS")
}

auto_fix_python() {
  print_warn "Python skipped (manual fix required)"
  print_info "Suggested: pkg reinstall python"
  skipped+=("Python")
}

auto_fix_git() {
  print_warn "Git requires manual fix"
  print_info "Suggested: pkg install git && git pull"
  skipped+=("Git")
}

auto_fix_termux_version() {
  print_warn "TermuxVersion requires manual inspection"
  skipped+=("TermuxVersion")
}

declare -A AUTO_FIX_MAP=(
  [Storage]=auto_fix_storage
  [Repository]=auto_fix_repository
  [NodeJS]=auto_fix_nodejs
  [Python]=auto_fix_python
  [Git]=auto_fix_git
  [TermuxVersion]=auto_fix_termux_version
)

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue
  if [[ "$value" == "BROKEN" || "$value" == "PARTIAL" ]]; then
    echo -e "🔹 Issue Detected: $key"
    read -rp "Run auto-fix for $key? [y/N]: " CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { print_skip "$key skipped"; skipped+=("$key"); continue; }
    "${AUTO_FIX_MAP[$key]}"
  fi
done < "$STATE_FILE"

report_append "auto" "$(printf '"%s",' "${fixed[@]}" | sed 's/,$//')" "$(printf '"%s",' "${skipped[@]}" | sed 's/,$//')"
print_ok "Auto-fix completed"
echo -e "${CYAN}Report saved:${RESET} $REPORT_FILE"
echo -e "${CYAN}Run:${RESET} tdoc status"
