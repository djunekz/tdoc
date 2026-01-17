#!/bin/bash

REPORT_DIR="$HOME/.tdoc"
REPORT_FILE="$REPORT_DIR/report.json"

mkdir -p "$REPORT_DIR"

report_init() {
  # Safe initialization
  if [ ! -f "$REPORT_FILE" ] || [ ! -s "$REPORT_FILE" ]; then
    echo "[]" > "$REPORT_FILE"
  fi
}

report_append() {
  local mode="$1"
  local fixed="$2"
  local skipped="$3"

  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"

  # Entry JSON
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

  # Append safely
  tmp=$(mktemp)
  # If file empty, write initial []
  [ ! -s "$REPORT_FILE" ] && echo "[]" > "$REPORT_FILE"
  # Remove trailing ] from existing file
  sed '$ s/]$//' "$REPORT_FILE" > "$tmp"
  # Add comma if not the first entry
  [ "$(tail -n 1 "$REPORT_FILE")" != "[" ] && echo "," >> "$tmp"
  # Append new entry
  echo "$entry" >> "$tmp"
  # Close array
  echo "]" >> "$tmp"
  # Replace original file
  mv "$tmp" "$REPORT_FILE"
}
