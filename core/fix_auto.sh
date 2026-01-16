#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# TDOC Fix Mode (AUTO)
# ==============================

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/repo.sh"

STATE_FILE="$TDOC_ROOT/data/state.env"

print_header "🤖 TDOC Fix Mode (AUTO)"
echo

if [ ! -f "$STATE_FILE" ]; then
  print_err "State file not found. Run: tdoc status"
  exit 1
fi

report_init

fixed=()
skipped=()

# ---------- AUTO FIX FUNCTIONS ----------

auto_fix_storage() {
  spinner_start "Auto-fixing Storage"
  termux-setup-storage >/dev/null 2>&1
  spinner_stop
  print_ok "Storage fixed"
  fixed+=("Storage")
}

auto_fix_repository() {
  spinner_start "Auto-fixing Repository"
  termux-change-repo
  spinner_stop
  print_ok "Repository configured"
  fixed+=("Repository")
}

auto_fix_nodejs() {
  spinner_start "Auto-installing NodeJS"
  pkg install -y nodejs >/dev/null 2>&1
  spinner_stop
  print_ok "NodeJS installed"
  fixed+=("NodeJS")
}

auto_fix_python() {
  print_warn "Python skipped (manual fix required)"
  print_info "Suggested: pkg reinstall python"
  skipped+=("Python")
}

# ---------- MAIN LOOP ----------

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue

  if [[ "$value" == "BROKEN" || "$value" == "PARTIAL" ]]; then
    case "$key" in
      Storage) auto_fix_storage ;;
      Repository) auto_fix_repository ;;
      NodeJS) auto_fix_nodejs ;;
      Python) auto_fix_python ;;
      *)
        print_warn "No auto-fix handler for $key"
        skipped+=("$key")
        ;;
    esac
  fi
done < "$STATE_FILE"

# ---------- REPORT ----------

report_append \
  "auto" \
  "$(printf '"%s",' "${fixed[@]}" | sed 's/,$//')" \
  "$(printf '"%s",' "${skipped[@]}" | sed 's/,$//')"

print_ok "Auto-fix completed"
echo -e "${CYAN}Report saved:${RESET} ~/.tdoc/report.json"
echo -e "${CYAN}Run:${RESET} tdoc status"
