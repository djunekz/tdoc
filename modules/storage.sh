#!/usr/bin/env bash

_tdoc_storage_direct_ok() {
  # Some users intentionally remove ~/storage (termux-setup-storage symlinks)
  # but still have working shared-storage access via the real Android paths.
  # Don't call it BROKEN just because the convenience symlink is gone.
  for p in "/storage/emulated/0" "/sdcard"; do
    if [[ -d "$p" ]] && ls "$p" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

check_storage_module() {
  if [[ -d "$HOME/storage/shared" && -w "$HOME/storage/shared" ]]; then
    echo "Storage=OK" >> "$STATE_FILE"
  elif _tdoc_storage_direct_ok; then
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
