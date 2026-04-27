#!/usr/bin/env bash
# TDOC — Fix Preview / Dry-Run

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/report.sh"
source "$TDOC_ROOT/core/ai_explain.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
print_header "👀 $(t L_FIX_PREVIEW_HEADER)"
echo -e "${GRAY}$(t L_FIX_PREVIEW_NOTE)${RESET}"
echo

if [[ ! -f "$STATE_FILE" ]]; then
  print_err "$(t L_FIX_NO_STATE)"; print_info "$(t L_FIX_RUN_SCAN)"; exit 1
fi

report_init
planned=(); skipped=()

while IFS='=' read -r key value; do
  [[ -z "$key" || "$value" == "OK" ]] && continue
  echo -e "${CYAN}[PREVIEW]${RESET} $key — ${RED}$value${RESET}"
  case "$key" in
    Storage)      echo -e "${GRAY}  → termux-setup-storage${RESET}";       planned+=("Storage") ;;
    Repository)   echo -e "${GRAY}  → termux-change-repo${RESET}";         planned+=("Repository") ;;
    NodeJS)       echo -e "${GRAY}  → pkg install nodejs${RESET}";         planned+=("NodeJS") ;;
    Python)       echo -e "${GRAY}  → pkg reinstall python${RESET}";       planned+=("Python") ;;
    Git)          echo -e "${GRAY}  → pkg install git${RESET}";            planned+=("Git") ;;
    TermuxVersion) echo -e "${GRAY}  → pkg update && pkg upgrade${RESET}"; skipped+=("TermuxVersion") ;;
    *)            echo -e "${GRAY}  → $(t L_FIX_NO_HANDLER) $key${RESET}"; skipped+=("$key") ;;
  esac
  echo
  ai_explain "$key"
  echo; echo "────────────────────────────────"; echo
done < "$STATE_FILE"

echo
print_header "$(t L_FIX_SUMMARY)"
print_ok   "$(t L_FIX_PLANNED) : ${#planned[@]}"
print_skip "$(t L_FIX_SKIPPED_COUNT) : ${#skipped[@]}"
echo
echo -e "${CYAN}$(t L_FIX_NEXT)${RESET} ${BOLD}tdoc fix --auto${RESET}"
