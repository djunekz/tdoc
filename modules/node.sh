#!/usr/bin/env bash

node() {
  if command -v node >/dev/null 2>&1; then
    echo "NodeJS=OK" >> "$STATE_FILE"
  else
    echo "NodeJS=BROKEN" >> "$STATE_FILE"
  fi
}
