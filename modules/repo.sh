#!/usr/bin/env bash
  if grep -q "packages.termux.dev" $PREFIX/etc/apt/sources.list 2>/dev/null; then
    echo "Repository=OK" >> "$STATE_FILE"
  else
    echo "Repository=BROKEN" >> "$STATE_FILE"
  fi
}
