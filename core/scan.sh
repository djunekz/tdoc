#!/data/data/com.termux/files/usr/bin/bash

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$TDOC_ROOT/data"
> "$STATE_FILE"

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/repo.sh"

print_header "🔍 TDOC System Scan"
echo

# Repository
spinner_start "Checking repository"
echo "Repository=$(detect_repository)" >> "$STATE_FILE"
spinner_stop
print_ok "Repository checked"

# Storage
spinner_start "Checking storage"
if [ -d "$HOME/storage" ] && [ -w "$HOME/storage/shared" ]; then
  echo "Storage=OK" >> "$STATE_FILE"
else
  echo "Storage=BROKEN" >> "$STATE_FILE"
fi
spinner_stop
print_ok "Storage checked"

# Python
spinner_start "Checking Python"
command -v python >/dev/null 2>&1 \
  && echo "Python=OK" >> "$STATE_FILE" \
  || echo "Python=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "Python checked"

# NodeJS
spinner_start "Checking NodeJS"
command -v node >/dev/null 2>&1 \
  && echo "NodeJS=OK" >> "$STATE_FILE" \
  || echo "NodeJS=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "NodeJS checked"

# Git
spinner_start "Checking Git"
command -v git >/dev/null 2>&1 \
  && echo "Git=OK" >> "$STATE_FILE" \
  || echo "Git=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "Git checked"

# Termux Version
spinner_start "Checking Termux version"
command -v termux-info >/dev/null 2>&1 \
  && echo "TermuxVersion=OK" >> "$STATE_FILE" \
  || echo "TermuxVersion=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "Termux version checked"
