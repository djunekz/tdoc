#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC Fix Mode (Manual, Compliant)
# ==============================

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/repo.sh"

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$HOME/.tdoc"
REPORT_FILE="$HOME/.tdoc/report.json"

print_header "🛠 TDOC Fix Mode (Manual)"
echo

report_init

fixed=()
skipped=()

# ---------- FIX FUNCTIONS ----------

fix_storage() {
    read -rp "${YELLOW}Run 'termux-setup-storage'? [y/N]: ${RESET}" CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { print_skip "Storage skipped"; skipped+=("Storage"); return; }
    spinner_start "Fixing Storage..."
    termux-setup-storage >/dev/null 2>&1
    spinner_stop
    print_ok "Storage fixed"
    fixed+=("Storage")
}

fix_repository() {
    print_info "Repository requires manual intervention"
    print_info "Run: termux-change-repo"
    skipped+=("Repository")
}

fix_nodejs() {
    read -rp "${YELLOW}Install NodeJS now? [y/N]: ${RESET}" CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { print_skip "NodeJS skipped"; skipped+=("NodeJS"); return; }
    spinner_start "Installing NodeJS..."
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

fix_git() {
    print_warn "Git requires manual intervention"
    print_info "Suggested: pkg install git && git pull"
    skipped+=("Git")
}

# ---------- FIX MAPPING ----------
declare -A FIX_MAP=(
    [Storage]=fix_storage
    [Repository]=fix_repository
    [NodeJS]=fix_nodejs
    [Python]=fix_python
    [Git]=fix_git
)

# ---------- MAIN LOOP ----------
while IFS='=' read -r key value; do
    [[ -z "$key" || "$value" == "OK" ]] && continue

    echo -e "${CYAN}Fix $key?${RESET}"
    select choice in "Yes" "Skip"; do
        case "$choice" in
            Yes) "${FIX_MAP[$key]}" ;;
            Skip) print_skip "$key skipped"; skipped+=("$key") ;;
            *) print_warn "Invalid selection"; continue ;;
        esac
        break
    done

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
done < "$STATE_FILE"

# ---------- REPORT ----------
report_append \
    "manual" \
    "$(printf '"%s",' "${fixed[@]}" | sed 's/,$//')" \
    "$(printf '"%s",' "${skipped[@]}" | sed 's/,$//')"

print_ok "Fix process finished"
echo -e "${CYAN}Report saved:${RESET} $REPORT_FILE"
echo -e "${CYAN}Run:${RESET} tdoc status"
