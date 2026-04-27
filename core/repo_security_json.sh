#!/usr/bin/env bash
# ==============================
# TDOC — Repository Security JSON
# ==============================

source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/repo_security.sh"

scan_repo_security

build_json_array() {
  local -a arr=("${@}")
  if [[ ${#arr[@]} -eq 0 ]]; then
    echo "[]"
    return
  fi
  local out="["
  for item in "${arr[@]}"; do
    item=$(printf '%s' "$item" | sed 's/"/\\"/g')
    out+="\"$item\","
  done
  out="${out%,}]"
  echo "$out"
}

json_warn=$(build_json_array "${WARNINGS[@]+"${WARNINGS[@]}"}")
json_danger=$(build_json_array "${DANGERS[@]+"${DANGERS[@]}"}")

cat <<EOF
{
  "tool": "$TDOC_NAME",
  "version": "$TDOC_VERSION",
  "codename": "$TDOC_CODENAME",
  "build_date": "$TDOC_BUILD_DATE",
  "mode": "security",
  "generated_at": "$(date -Iseconds)",
  "security": {
    "state": "$SECURITY_STATE",
    "warnings": $json_warn,
    "dangers": $json_danger
  }
}
EOF
