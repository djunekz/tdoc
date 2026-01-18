#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Status (UI-compliant)
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/ai_explain.sh"

JSON_OUTPUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=1

OK_ICON="$ICON_OK"
BROKEN_ICON="$ICON_ERR"

# Header
if [[ $JSON_OUTPUT -eq 0 ]]; then
  print_header "🧪 TDOC — Status Report"
  echo "Tool:"
  echo "  Name: $TDOC_NAME"
  echo "  Version: $TDOC_VERSION ($TDOC_CODENAME)"
  echo "  Build Date: $TDOC_BUILD_DATE"
  echo
fi

# State processing
ok=0
broken=0
json_system=""

while IFS='=' read -r key value; do
  [[ -z "$key" ]] && continue
  json_system+="\"$key\":\"$value\","

  if [[ $JSON_OUTPUT -eq 0 ]]; then
    if [[ "$value" == "OK" ]]; then
      print_ok "$key"
      ok=$((ok + 1))
    else
      print_err "$key"
      ai_explain "$key" | while IFS= read -r line; do
        print_info "$line"
      done
      broken=$((broken + 1))
    fi
  else
    [[ "$value" == "OK" ]] && ok=$((ok + 1)) || broken=$((broken + 1))
  fi
done < "$STATE_FILE"

json_system="${json_system%,}"

# Summary
if [[ $JSON_OUTPUT -eq 0 ]]; then
  echo
  print_info "Summary: $ok OK, $broken Broken"
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
