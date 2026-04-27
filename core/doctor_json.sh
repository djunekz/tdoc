#!/usr/bin/env bash
# ==============================
# TDOC — Doctor JSON Output
# ==============================

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"

source "$TDOC_ROOT/core/version.sh"

escape_json() {
  printf '%s' "$1" | awk '{
    gsub(/\\/, "\\\\")
    gsub(/"/, "\\\"")
    gsub(/\t/, "\\t")
    gsub(/\r/, "\\r")
    if (NR > 1) printf "\\n"
    printf "%s", $0
  }'
}

get_termux_version() {
  local ver
  ver=$(dpkg-query -W -f='${Version}' termux-tools 2>/dev/null || true)
  if [[ -n "$ver" ]]; then
    echo "$ver"
  elif [[ -n "${TERMUX_VERSION:-}" ]]; then
    echo "$TERMUX_VERSION"
  else
    echo "unknown"
  fi
}

get_git_info() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch commit
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    commit=$(git rev-parse HEAD 2>/dev/null)
    printf '{"branch":"%s","commit":"%s"}' "$branch" "$commit"
  else
    echo "{}"
  fi
}

if [[ ! -f "$STATE_FILE" ]]; then
  cat <<EOF
{
  "tool": "$TDOC_NAME",
  "version": "$TDOC_VERSION",
  "codename": "$TDOC_CODENAME",
  "build_date": "$TDOC_BUILD_DATE",
  "mode": "doctor",
  "error": "state_not_found",
  "hint": "run: tdoc scan"
}
EOF
  exit 1
fi

ok=0
broken=0
partial=0
json_system=""

while IFS='=' read -r key value; do
  [[ -z "$key" ]] && continue
  key_lc=$(echo "$key" | tr 'A-Z' 'a-z')
  escaped_val=$(escape_json "$value")
  json_system+="\"$key_lc\":\"$escaped_val\","

  case "$value" in
    OK)      ok=$((ok + 1)) ;;
    PARTIAL) partial=$((partial + 1)) ;;
    *)       broken=$((broken + 1)) ;;
  esac
done < "$STATE_FILE"

json_system="${json_system%,}"

TERMUX_VER=$(get_termux_version)
GIT_INFO=$(get_git_info)

cat <<EOF
{
  "tool": "$TDOC_NAME",
  "version": "$TDOC_VERSION",
  "codename": "$TDOC_CODENAME",
  "build_date": "$TDOC_BUILD_DATE",
  "mode": "doctor",
  "termux_version": "$TERMUX_VER",
  "git": $GIT_INFO,
  "generated_at": "$(date -Iseconds)",
  "system": {
    $json_system
  },
  "summary": {
    "ok": $ok,
    "partial": $partial,
    "broken": $broken
  }
}
EOF
