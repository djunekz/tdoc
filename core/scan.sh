#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — System Scan (UI-enhanced)
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$TDOC_ROOT/data"
: > "$STATE_FILE"

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
echo -e "${CYAN}🧪 TDOC — System Scan${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo

# -----------------------
# Helper: check command
# -----------------------
check_item() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" >/dev/null 2>&1; then
        echo "$name=OK" >> "$STATE_FILE"
        echo -e " [${GREEN}$OK_ICON${RESET}] $name"
    else
        echo "$name=BROKEN" >> "$STATE_FILE"
        echo -e " [${RED}$BROKEN_ICON${RESET}] $name"
    fi
}

# -----------------------
# Run checks
# -----------------------
check_item "Repository" "command -v apt"
check_item "Storage" "[[ -d \"$HOME/storage\" && -w \"$HOME/storage/shared\" ]]"
check_item "Python" "command -v python"
check_item "NodeJS" "command -v node"
check_item "Git" "command -v git"
check_item "TermuxVersion" "command -v termux-info"

# -----------------------
# Summary
# -----------------------
ok=0
broken=0

while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    [[ "$value" == "OK" ]] && ok=$((ok + 1)) || broken=$((broken + 1))
done < "$STATE_FILE"

echo
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${CYAN}📝 TDOC Scan Summary${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${GREEN}OK     : $ok${RESET}"
echo -e "${RED}Broken : $broken${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo
echo -e "✔ TDOC scan completed"
