#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# TDOC — Doctor JSON Output
# ==============================

STATE_FILE="$TDOC_ROOT/data/state.env"

# Load version (single source of truth)
source "$TDOC_ROOT/core/version.sh"

if [ ! -f "$STATE_FILE" ]; then
  cat <<EOF
{
  "tool": "$TDOC_NAME",
  "error": "state_not_found",
  "hint": "run tdoc status"
}
EOF
  exit 1
fi

ok=0
broken=0
json_system=""

while IFS='=' read -r key value; do
  [ -z "$key" ] && continue

  key_lc=$(echo "$key" | tr 'A-Z' 'a-z')
  json_system+="\"$key_lc\":\"$value\","

  if [ "$value" = "OK" ]; then
    ok=$((ok + 1))
  else
    broken=$((broken + 1))
  fi
done < "$STATE_FILE"

# remove trailing comma
json_system="${json_system%,}"

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
