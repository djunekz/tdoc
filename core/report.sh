#!/usr/bin/env bash
# ==============================
# TDOC — Report Engine
# ==============================

REPORT_DIR="$HOME/.tdoc"
REPORT_FILE="$REPORT_DIR/report.json"

mkdir -p "$REPORT_DIR"

report_init() {
  if [[ ! -f "$REPORT_FILE" ]]; then
    echo "[]" > "$REPORT_FILE"
  fi
}

_json_escape() {
  printf '%s' "$1" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e ':a;N;$!ba;s/\n/\\n/g'
}

_json_array() {
  local out=""
  for item in "$@"; do
    item=$(_json_escape "$item")
    out+="\"$item\","
  done
  echo "[${out%,}]"
}

report_append_manual() {
  local -a fixed=()
  local -a skipped=()
  local target="fixed"

  for arg in "$@"; do
    if [[ "$arg" == "--skipped" ]]; then
      target="skipped"
      continue
    fi
    if [[ "$target" == "fixed" ]]; then
      fixed+=("$arg")
    else
      skipped+=("$arg")
    fi
  done

  _report_write "manual" fixed skipped
}

report_append_auto() {
  local -a fixed=("$@")
  local -a skipped=()
  _report_write "auto" fixed skipped
}

report_append() {
  local mode="$1"
  local planned_str="$2"
  local skipped_str="$3"
  local -a fixed=()
  local -a skipped=()

  IFS=',' read -ra fixed <<< "$planned_str"
  IFS=',' read -ra skipped <<< "$skipped_str"

  _report_write "$mode" fixed skipped
}

_report_write() {
  local mode="$1"
  local fixed_varname="$2"
  local skipped_varname="$3"

  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"

  local -a fixed_arr=()
  local -a skipped_arr=()
  eval "fixed_arr=(\"\${${fixed_varname}[@]+\${${fixed_varname}[@]}}\")"
  eval "skipped_arr=(\"\${${skipped_varname}[@]+\${${skipped_varname}[@]}}\")"

  local fixed_json
  local skipped_json
  fixed_json=$(_json_array "${fixed_arr[@]+"${fixed_arr[@]}"}")
  skipped_json=$(_json_array "${skipped_arr[@]+"${skipped_arr[@]}"}")

  local entry
  entry=$(cat <<EOF
{
  "time": "$now",
  "mode": "$mode",
  "fixed": $fixed_json,
  "skipped": $skipped_json
}
EOF
)

  local tmp
  tmp="$(mktemp)"

  if [[ ! -s "$REPORT_FILE" ]] || [[ "$(cat "$REPORT_FILE")" == "[]" ]]; then
    printf '[\n%s\n]\n' "$entry" > "$tmp"
  else
    sed '$d' "$REPORT_FILE" > "$tmp"
    printf ',\n%s\n]\n' "$entry" >> "$tmp"
  fi

  mv "$tmp" "$REPORT_FILE"
}
