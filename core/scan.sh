#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — System Scan (UI-enhanced, v1.0.4)
# ==============================

STATE_FILE="$PREFIX/var/lib/tdoc/state.env"
mkdir -p "$(dirname "$STATE_FILE")"
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
# Run repository security scan
# -----------------------
source "$TDOC_ROOT/core/repo_security.sh"
scan_repo_security

# -----------------------
# Run checks
# -----------------------
# Storage check → write permission
check_item "Storage" "[[ -w \"$HOME\" ]]"

# Interpreter/tools → dummy script execution
check_item "Python" "python -c 'print(\"OK\")'"
check_item "NodeJS" "node -e 'console.log(\"OK\")'"
check_item "Git" "git --version >/dev/null 2>&1"
check_item "TermuxVersion" "termux-info >/dev/null 2>&1"

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
