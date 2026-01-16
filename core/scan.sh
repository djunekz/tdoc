#!/data/data/com.termux/files/usr/bin/bash

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$TDOC_ROOT/data"
> "$STATE_FILE"

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/repo.sh"

print_header "🔍 TDOC System Scan"
echo

spinner_start "Checking repository"
echo "Repository=$(detect_repository)" >> "$STATE_FILE"
spinner_stop
print_ok "Repository checked"

spinner_start "Checking storage"
if [ -d "$HOME/storage" ]; then
  echo "Storage=OK" >> "$STATE_FILE"
else
  echo "Storage=BROKEN" >> "$STATE_FILE"
fi
spinner_stop
print_ok "Storage checked"

spinner_start "Checking Python"
command -v python >/dev/null 2>&1 \
  && echo "Python=OK" >> "$STATE_FILE" \
  || echo "Python=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "Python checked"

spinner_start "Checking NodeJS"
command -v node >/dev/null 2>&1 \
  && echo "NodeJS=OK" >> "$STATE_FILE" \
  || echo "NodeJS=BROKEN" >> "$STATE_FILE"
spinner_stop
print_ok "NodeJS checked"
