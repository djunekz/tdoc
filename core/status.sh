#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Combined CLI + JSON Status
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"

# Load version & explanations
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/ai_explain.sh"

# Colors & icons
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"
OK_ICON="✅"
BROKEN_ICON="❌"

# Flags
JSON_OUTPUT=0
if [[ "$1" == "--json" ]]; then
    JSON_OUTPUT=1
fi

# Termux version
get_termux_version() {
    if command -v termux-info >/dev/null 2>&1; then
        termux-info | grep -i "Version" | awk '{print $2}' || echo "unknown"
    else
        echo "unknown"
    fi
}

# Git info
get_git_info() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        commit=$(git rev-parse HEAD 2>/dev/null)
        echo "$branch ($commit)"
    else
        echo "N/A"
    fi
}

# Check state file
if [ ! -f "$STATE_FILE" ]; then
    if [ $JSON_OUTPUT -eq 1 ]; then
        cat <<EOF
{
  "tool": "$TDOC_NAME",
  "error": "state_not_found",
  "hint": "run tdoc scan"
}
EOF
    else
        echo -e "${RED}❌ State file not found!${RESET}"
        echo "Run: tdoc scan"
    fi
    exit 1
fi

# Prepare counters & JSON
ok=0
broken=0
json_system=""

if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${CYAN}🧪 TDOC — Status Report${RESET}"
    echo -e "Tool: $TDOC_NAME"
    echo -e "Version: $TDOC_VERSION ($TDOC_CODENAME)"
    echo -e "Build Date: $TDOC_BUILD_DATE"
    echo -e "Termux Version: $(get_termux_version)"
    echo -e "Git: $(get_git_info)"
    echo
fi

while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue

    # For JSON
    json_system+="\"$key\":\"$value\","

    # CLI output
    if [ $JSON_OUTPUT -eq 0 ]; then
        if [ "$value" = "OK" ]; then
            echo -e "${GREEN}$OK_ICON $key: $value${RESET}"
            ok=$((ok + 1))
        else
            echo -e "${RED}$BROKEN_ICON $key: $value${RESET}"
            # Explanation
            ai_explain "$key" | while IFS= read -r line; do
                echo -e "  ${YELLOW}$line${RESET}"
            done
            broken=$((broken + 1))
        fi
    else
        # Count JSON summary
        if [ "$value" = "OK" ]; then
            ok=$((ok + 1))
        else
            broken=$((broken + 1))
        fi
    fi
done < "$STATE_FILE"

# Remove trailing comma for JSON
json_system="${json_system%,}"

# CLI summary
if [ $JSON_OUTPUT -eq 0 ]; then
    echo
    echo -e "${CYAN}📝 Summary:${RESET} $ok OK, $broken Broken"
    echo
else
    # Output JSON
    cat <<EOF
{
  "tool": "$TDOC_NAME",
  "version": "$TDOC_VERSION",
  "codename": "$TDOC_CODENAME",
  "build_date": "$TDOC_BUILD_DATE",
  "mode": "doctor",
  "generated_at": "$(date -Iseconds)",
  "system": {
    $json_system
  },
  "summary": {
    "ok": $ok,
    "broken": $broken
  }
}
EOF
fi
