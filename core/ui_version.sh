#!/usr/bin/env bash
# ============================================================
# TDOC — core/ui_version.sh
# ============================================================

source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/ui.sh"

tdoc_version_ui() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${CYAN}🛰  TDOC — Version Info${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
  echo -e "  ${GREEN}Name     :${RESET} ${BOLD}${TDOC_NAME}${RESET}"
  echo -e "  ${GREEN}Version  :${RESET} ${BOLD}${TDOC_VERSION}${RESET}"
  [[ -n "${TDOC_CODENAME}"   ]] && \
    echo -e "  ${GREEN}Codename :${RESET} ${BOLD}${TDOC_CODENAME}${RESET}"
  [[ -n "${TDOC_BUILD_DATE}" ]] && \
    echo -e "  ${GREEN}Build    :${RESET} ${BOLD}${TDOC_BUILD_DATE}${RESET}"
  echo
  echo -e "  ${DIM}ℹ Run 'tdoc help' for usage${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}
