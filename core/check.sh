#!/usr/bin/env bash
# TDOC — Package Check

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

PACKAGE="${1:-}"

if [[ -z "$PACKAGE" ]]; then
  print_err "$(t L_CHECK_NO_PKG)"; echo
  echo "$(t L_CHECK_USAGE)"; echo
  echo "$(t L_CHECK_EXAMPLES):"
  echo "  tdoc check curl"; echo "  tdoc check ruby"
  echo "  tdoc check ffmpeg"; echo "  tdoc check openssh"
  exit 1
fi

print_header "🔎 $(t L_CHECK_HEADER): $PACKAGE"
echo

BINARY_PATH=$(command -v "$PACKAGE" 2>/dev/null || true)
if [[ -n "$BINARY_PATH" ]]; then
  print_ok "$(t L_CHECK_BINARY_FOUND): $BINARY_PATH"
else
  print_err "$(t L_CHECK_BINARY_MISSING): $PACKAGE"
fi
echo

echo -e "${CYAN}$(t L_CHECK_DPKG):${RESET}"
if ! dpkg-query -W -f='  Package: ${Package}\n  Version: ${Version}\n  Status : ${db:Status-Status}\n' "$PACKAGE" 2>/dev/null; then
  echo -e "  ${GRAY}$(t L_CHECK_NOT_REGISTERED)${RESET}"
fi
echo

echo -e "${CYAN}$(t L_CHECK_REPO):${RESET}"
if ! apt-cache show "$PACKAGE" 2>/dev/null | grep -E '(Package|Version|Description)' | head -6; then
  echo -e "  ${GRAY}$(t L_CHECK_NOT_IN_REPO)${RESET}"
  echo -e "  ${GRAY}$(t L_CHECK_REPO_HINT)${RESET}"
fi
echo

[[ -z "$BINARY_PATH" ]] && print_info "$(t L_CHECK_INSTALL_HINT): pkg install $PACKAGE"
