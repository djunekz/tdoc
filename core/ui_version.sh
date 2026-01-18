#!/data/data/com.termux/files/usr/bin/env bash
# ==============================
# TDOC — Version Info (Minimal UI)
# ==============================

# Colors & Styles
BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[36m"
GREEN="\e[32m"
RESET="\e[0m"
ICON_INFO="ℹ"

tdoc_version_ui() {
    # Border hanya untuk header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${CYAN}🛰 TDOC — Version Info${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    # Detail tanpa border
    echo -e "${GREEN}Name: ${TDOC_NAME}${RESET}"
    echo -e "${GREEN}Version: ${TDOC_VERSION}${RESET}"
    echo -e "${GREEN}Codename: ${TDOC_CODENAME}${RESET}"
    echo -e "${GREEN}Build Date: ${TDOC_BUILD_DATE}${RESET}"
    echo -e "\n${DIM}${ICON_INFO} Run 'tdoc help' for usage${RESET}"
}
