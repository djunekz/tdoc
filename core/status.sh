#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Status
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"

# Load metadata
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/ai_explain.sh"

# Colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

OK_ICON="✔"
BROKEN_ICON="✖"

# Flags
JSON_OUTPUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=1

# --------------------------------------------------
# Helpers
# --------------------------------------------------

get_termux_version() {
  # Method 1: apt-cache (PALING STABIL)
  if command -v apt-cache >/dev/null 2>&1; then
    local v
    v="$(apt-cache policy termux-tools 2>/dev/null | awk '/Installed:/ {print $2}')"
    [[ -n "$v" && "$v" != "(none)" ]] && { echo "$v"; return; }
  fi

  # Method 2: dpkg-query fallback
  if command -v dpkg-query >/dev/null 2>&1; then
    local v
    v="$(dpkg-query -W -f='${Version}\n' termux-tools 2>/dev/null)"
    [[ -n "$v" ]] && { echo "$v"; return; }
  fi

  echo "unknown"
}

get_android_info() {
  local ver sdk
  ver="$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  sdk="$(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
  echo "$ver (SDK $sdk)"
}

get_git_info() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$(git branch --show-current) ($(git rev-parse --short HEAD))"
  fi
}

# --------------------------------------------------
# State check
# --------------------------------------------------

if [[ ! -f "$STATE_FILE" ]]; then
  if [[ $JSON_OUTPUT -eq 1 ]]; then
    cat <<EOF
{
  "tool": "$TDOC_NAME",
  "error": "state_not_found",
  "hint": "run tdoc status"
}
EOF
  else
    echo -e "${RED}❌ State file not found${RESET}"
    echo "Run: tdoc status"
  fi
  exit 1
fi

# --------------------------------------------------
# Header
# --------------------------------------------------

if [[ $JSON_OUTPUT -eq 0 ]]; then
  echo -e "${CYAN}🧪 TDOC — Status Report${RESET}"
  echo
  echo "Tool:"
  echo "  Name: $TDOC_NAME"
  echo "  Version: $TDOC_VERSION ($TDOC_CODENAME)"
  echo "  Build Date: $TDOC_BUILD_DATE"
  echo
  echo "Environment:"
  echo "  Termux Version: $(get_termux_version)"
  echo "  Android: $(get_android_info)"

  git_info="$(get_git_info)"
  [[ -n "$git_info" ]] && echo "  Git: $git_info"
  echo
fi

# --------------------------------------------------
# Process state
# --------------------------------------------------

ok=0
broken=0
json_system=""

while IFS='=' read -r key value; do
  [[ -z "$key" ]] && continue

  json_system+="\"$key\":\"$value\","

  if [[ $JSON_OUTPUT -eq 0 ]]; then
    if [[ "$value" == "OK" ]]; then
      echo -e "${GREEN}$OK_ICON $key${RESET}"
      ok=$((ok + 1))
    else
      echo -e "${RED}$BROKEN_ICON $key${RESET}"
      ai_explain "$key" | while IFS= read -r line; do
        echo -e "  ${YELLOW}$line${RESET}"
      done
      broken=$((broken + 1))
    fi
  else
    [[ "$value" == "OK" ]] && ok=$((ok + 1)) || broken=$((broken + 1))
  fi
done < "$STATE_FILE"

json_system="${json_system%,}"

# --------------------------------------------------
# Summary
# --------------------------------------------------

if [[ $JSON_OUTPUT -eq 0 ]]; then
  echo
  echo -e "${CYAN}Summary:${RESET} $ok OK, $broken Broken"
else
  cat <<EOF
{
  "tool": "$TDOC_NAME",
  "version": "$TDOC_VERSION",
  "codename": "$TDOC_CODENAME",
  "build_date": "$TDOC_BUILD_DATE",
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
