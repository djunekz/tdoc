#!/usr/bin/env bash

python_check() {
  if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    echo "Python=OK" >> "$STATE_FILE"
  else
    echo "Python=BROKEN" >> "$STATE_FILE"
  fi
}
