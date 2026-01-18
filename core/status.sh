#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Status Report (UI-enhanced, Device Info)
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"
source "$TDOC_ROOT/core/version.sh"

# -----------------------
# Colors & Icons
# -----------------------
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

OK_ICON="✔"
BROKEN_ICON="✖"
BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -----------------------
# Header
# -----------------------
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${CYAN}🧪 TDOC — Status Report${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo

# -----------------------
# Tool Info
# -----------------------
echo "Tool:"
echo "  Name: $TDOC_NAME"
echo "  Version: $TDOC_VERSION ($TDOC_CODENAME)"
echo "  Build Date: $TDOC_BUILD_DATE"
echo

# -----------------------
# Environment Info
# -----------------------
TERMUX_VER="$(dpkg-query -W -f='${Version}' termux-tools 2>/dev/null || echo unknown)"
ANDROID_VER="$(getprop ro.build.version.release 2>/dev/null || echo unknown) (SDK $(getprop ro.build.version.sdk 2>/dev/null || echo unknown))"
DEVICE_MANUF="$(getprop ro.product.manufacturer 2>/dev/null || echo unknown)"
DEVICE_MODEL="$(getprop ro.product.model 2>/dev/null || echo unknown)"
SYSTEM_BUILD="$(getprop ro.build.display.id 2>/dev/null || echo unknown)"
CHECKED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

echo "Environment:"
echo "  Termux Version: $TERMUX_VER"
echo "  Android: $ANDROID_VER"
echo "  Device: $DEVICE_MANUF $DEVICE_MODEL"
echo "  System: $SYSTEM_BUILD"
echo "  Checked at: $CHECKED_AT"
echo

# -----------------------
# Display last saved state
# -----------------------
if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${BROKEN_ICON} State file not found!"
  echo "Run: tdoc scan"
  exit 1
fi

ok=0
broken=0

while IFS='=' read -r key value; do
  [[ -z "$key" ]] && continue
  if [[ "$value" == "OK" ]]; then
    echo -e "${GREEN}$OK_ICON $key${RESET}"
    ok=$((ok + 1))
  else
    echo -e "${RED}$BROKEN_ICON $key${RESET}"
    broken=$((broken + 1))
  fi
done < "$STATE_FILE"

# -----------------------
# Summary
# -----------------------
echo
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${CYAN}📝 TDOC Status Summary${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${GREEN}OK     : $ok${RESET}"
echo -e "${RED}Broken : $broken${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
