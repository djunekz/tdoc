#!/data/data/com.termux/files/usr/bin/bash
#
# TDOC — System Scan (UI + Logic)
#

STATE_FILE="$TDOC_ROOT/data/state.env"
mkdir -p "$TDOC_ROOT/data"
: > "$STATE_FILE"

source "$TDOC_ROOT/core/ui.sh"

print_header "🔍 TDOC System Scan"

# -------- Repository --------
spinner_start "Checking repository..."
if command -v apt >/dev/null 2>&1; then
  echo "Repository=OK" >> "$STATE_FILE"
  print_ok "Repository OK"
else
  echo "Repository=BROKEN" >> "$STATE_FILE"
  print_err "Repository BROKEN"
fi
spinner_stop

# -------- Storage --------
spinner_start "Checking storage..."
if [[ -d "$HOME/storage" && -w "$HOME/storage/shared" ]]; then
  echo "Storage=OK" >> "$STATE_FILE"
  print_ok "Storage OK"
else
  echo "Storage=BROKEN" >> "$STATE_FILE"
  print_err "Storage BROKEN"
fi
spinner_stop

# -------- Python --------
spinner_start "Checking Python..."
if command -v python >/dev/null 2>&1; then
  echo "Python=OK" >> "$STATE_FILE"
  print_ok "Python OK"
else
  echo "Python=BROKEN" >> "$STATE_FILE"
  print_err "Python BROKEN"
fi
spinner_stop

# -------- NodeJS --------
spinner_start "Checking NodeJS..."
if command -v node >/dev/null 2>&1; then
  echo "NodeJS=OK" >> "$STATE_FILE"
  print_ok "NodeJS OK"
else
  echo "NodeJS=BROKEN" >> "$STATE_FILE"
  print_err "NodeJS BROKEN"
fi
spinner_stop

# -------- Git --------
spinner_start "Checking Git..."
if command -v git >/dev/null 2>&1; then
  echo "Git=OK" >> "$STATE_FILE"
  print_ok "Git OK"
else
  echo "Git=BROKEN" >> "$STATE_FILE"
  print_err "Git BROKEN"
fi
spinner_stop

# -------- TermuxVersion --------
spinner_start "Checking Termux..."
if command -v termux-info >/dev/null 2>&1; then
  echo "TermuxVersion=OK" >> "$STATE_FILE"
  print_ok "TermuxVersion OK"
else
  echo "TermuxVersion=BROKEN" >> "$STATE_FILE"
  print_err "TermuxVersion BROKEN"
fi
spinner_stop

echo
print_info "System scan completed. Run 'tdoc status' for full summary."
