#!/usr/bin/env bash
# ==============================
# TDOC — Version Info (Enhanced UI)
# ==============================

source "$TDOC_ROOT/core/version.sh"

BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"
ICON_INFO="ℹ"
BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HEADER_ICON="🛰"

tdoc_version_ui() {
    echo -e "${CYAN}$BORDER${RESET}"
    echo -e "${BOLD}${CYAN}${HEADER_ICON} TDOC — Version Info${RESET}"
    echo -e "${CYAN}$BORDER${RESET}"
    echo

    echo -e "${GREEN}Name     : ${BOLD}$TDOC_NAME${RESET}"
    echo -e "${GREEN}Version  : ${BOLD}$TDOC_VERSION${RESET}"
    echo -e "${GREEN}Codename : ${BOLD}$TDOC_CODENAME${RESET}"
    echo -e "${GREEN}Build    : ${BOLD}$TDOC_BUILD_DATE${RESET}"
    echo

    echo -e "${DIM}${ICON_INFO} Run 'tdoc help' for usage${RESET}"
    echo -e "${CYAN}$BORDER${RESET}"
}
