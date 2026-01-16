#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# TDOC Fix Mode (Manual)
# ==============================

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/repo.sh"

STATE_FILE="$TDOC_ROOT/data/state.env"

print_header "🛠 TDOC Fix Mode (Manual)"
echo

if [ ! -f "$STATE_FILE" ]; then
  print_err "State file not found. Run: tdoc status"
  exit 1
fi

report_init

fixed=()
skipped=()

# ---------- FIX FUNCTIONS ----------

fix_storage() {
  spinner_start "Running termux-setup-storage"
  termux-setup-storage >/dev/null 2>&1
  spinner_stop
  print_ok "Storage fixed"
  fixed+=("Storage")
}

fix_repository() {
  spinner_start "Opening repository selector"
  termux-change-repo
  spinner_stop
  print_ok "Repository configured"
  fixed+=("Repository")
}

fix_nodejs() {
  spinner_start "Installing NodeJS"
  pkg install -y nodejs >/dev/null 2>&1
  spinner_stop
  print_ok "NodeJS installed"
  fixed+=("NodeJS")
}

fix_python() {
  print_warn "Python requires manual intervention"
  print_info "Suggested: pkg reinstall python"
  skipped+=("Python")
}

# ---------- MAIN LOOP ----------

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue

  if [[ "$value" == "BROKEN" || "$value" == "PARTIAL" ]]; then
    echo -e "${CYAN}Fix $key ?${RESET}"
    echo "  1) Yes"
    echo "  2) Skip"
    read -rp "> " choice

    case "$choice" in
      1)
        case "$key" in
          Storage) fix_storage ;;
          Repository) fix_repository ;;
          NodeJS) fix_nodejs ;;
          Python) fix_python ;;
          *)
            print_warn "No fix handler for $key"
            skipped+=("$key")
            ;;
        esac
        ;;
      *)
        print_skip "$key skipped"
        skipped+=("$key")
        ;;
    esac

    echo "--------------------------------"
  fi
done < "$STATE_FILE"

# ---------- REPORT ----------

report_append \
  "manual" \
  "$(printf '"%s",' "${fixed[@]}" | sed 's/,$//')" \
  "$(printf '"%s",' "${skipped[@]}" | sed 's/,$//')"

print_ok "Fix process finished"
echo -e "${CYAN}Report saved:${RESET} ~/.tdoc/report.json"
echo -e "${CYAN}Run:${RESET} tdoc status"
