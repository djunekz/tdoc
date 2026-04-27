#!/usr/bin/env bash

check_storage_module() {
  if [[ -d "$HOME/storage/shared" && -w "$HOME/storage/shared" ]]; then
    echo "Storage=OK" >> "$STATE_FILE"
  elif [[ -d "$HOME/storage" ]]; then
    echo "Storage=PARTIAL" >> "$STATE_FILE"
  else
    echo "Storage=BROKEN" >> "$STATE_FILE"
  fi
}

storage() {
  check_storage_module
}
