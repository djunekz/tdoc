#!/data/data/com.termux/files/usr/bin/bash

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/update_config.sh"

print_header "🔍 TDOC Update Check"
echo

# fetch latest release
LATEST_VERSION=$(curl -s "$TDOC_RELEASE_API" | grep '"tag_name"' | head -1 | cut -d '"' -f4)

if [ -z "$LATEST_VERSION" ]; then
  print_warn "Failed to check updates (network or API)"
  exit 1
fi

echo "Current version : $TDOC_VERSION"
echo "Latest version  : $LATEST_VERSION"
echo

if [ "$TDOC_VERSION" = "$LATEST_VERSION" ]; then
  print_ok "TDOC is up to date"
else
  print_warn "Update available"
  echo -e "${CYAN}Run:${RESET} tdoc update"
fi
