#!/bin/bash

REPORT_DIR="$HOME/.tdoc"
REPORT_FILE="$REPORT_DIR/report.json"

mkdir -p "$REPORT_DIR"

report_init() {
  [ ! -f "$REPORT_FILE" ] && echo "[]" > "$REPORT_FILE"
}

report_append() {
  local mode="$1"
  local fixed="$2"
  local skipped="$3"

  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"

  local entry
  entry=$(cat <<EOF
{
  "time": "$now",
  "mode": "$mode",
  "fixed": [$fixed],
  "skipped": [$skipped]
}
EOF
)

  # Append JSON safely (bash-only, no jq)
  tmp=$(mktemp)
  sed '$ s/]$//' "$REPORT_FILE" > "$tmp"
  [ "$(tail -n 1 "$REPORT_FILE")" != "[" ] && echo "," >> "$tmp"
  echo "$entry" >> "$tmp"
  echo "]" >> "$tmp"
  mv "$tmp" "$REPORT_FILE"
}
