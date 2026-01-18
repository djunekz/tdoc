#!/data/data/com.termux/files/usr/bin/bash
#
# TDOC — System Scan (logic only)
#

STATE_FILE="$TDOC_ROOT/data/state.env"

mkdir -p "$TDOC_ROOT/data"
: > "$STATE_FILE"

# Repository
if command -v apt >/dev/null 2>&1; then
  echo "Repository=OK" >> "$STATE_FILE"
else
  echo "Repository=BROKEN" >> "$STATE_FILE"
fi

# Storage
if [[ -d "$HOME/storage" && -w "$HOME/storage/shared" ]]; then
  echo "Storage=OK" >> "$STATE_FILE"
else
  echo "Storage=BROKEN" >> "$STATE_FILE"
fi

# Python
if command -v python >/dev/null 2>&1; then
  echo "Python=OK" >> "$STATE_FILE"
else
  echo "Python=BROKEN" >> "$STATE_FILE"
fi

# NodeJS
if command -v node >/dev/null 2>&1; then
  echo "NodeJS=OK" >> "$STATE_FILE"
else
  echo "NodeJS=BROKEN" >> "$STATE_FILE"
fi

# Git
if command -v git >/dev/null 2>&1; then
  echo "Git=OK" >> "$STATE_FILE"
else
  echo "Git=BROKEN" >> "$STATE_FILE"
fi

# Termux
if command -v termux-info >/dev/null 2>&1; then
  echo "TermuxVersion=OK" >> "$STATE_FILE"
else
  echo "TermuxVersion=BROKEN" >> "$STATE_FILE"
fi
