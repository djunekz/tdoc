#!/usr/bin/env bash
# TDOC — History

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

REPORT_FILE="$HOME/.tdoc/report.json"
print_header "📜 $(t L_HISTORY_HEADER)"
echo

if [[ ! -f "$REPORT_FILE" ]]; then
  print_warn "$(t L_HISTORY_EMPTY)"; exit 0
fi

LABEL_FIXED="$(t L_HISTORY_FIXED)"
LABEL_SKIPPED="$(t L_HISTORY_SKIPPED)"
LABEL_NO_ACTION="$(t L_HISTORY_NO_ACTION)"
LABEL_TOTAL="$(t L_HISTORY_TOTAL)"
LABEL_ENTRIES="$(t L_HISTORY_ENTRIES)"
LABEL_CORRUPT="$(t L_HISTORY_CORRUPT)"

if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  PYTHON=$(command -v python3 2>/dev/null || command -v python)
  "$PYTHON" - "$REPORT_FILE" \
    "$LABEL_FIXED" "$LABEL_SKIPPED" "$LABEL_NO_ACTION" \
    "$LABEL_TOTAL" "$LABEL_ENTRIES" "$LABEL_CORRUPT" << 'PYEOF'
import json, sys

report_file = sys.argv[1]
lbl_fixed      = sys.argv[2]
lbl_skipped    = sys.argv[3]
lbl_no_action  = sys.argv[4]
lbl_total      = sys.argv[5]
lbl_entries    = sys.argv[6]
lbl_corrupt    = sys.argv[7]

CYAN  = "\033[36m"; GREEN = "\033[32m"
GRAY  = "\033[90m"; RESET = "\033[0m"; BOLD  = "\033[1m"

with open(report_file) as f:
    try:
        records = json.load(f)
    except json.JSONDecodeError:
        print(f"  {lbl_corrupt}"); sys.exit(0)

if not records:
    print(f"  {lbl_no_action}"); sys.exit(0)

for i, r in enumerate(reversed(records), 1):
    time    = r.get("time", "?")
    mode    = r.get("mode", "?")
    fixed   = r.get("fixed", [])
    skipped = r.get("skipped", [])
    mode_color = GREEN if mode == "auto" else CYAN
    print(f"{BOLD}[{i:02d}]{RESET} {GRAY}{time}{RESET}  {mode_color}{mode}{RESET}")
    if fixed:   print(f"     {GREEN}✔ {lbl_fixed}:{RESET} {', '.join(fixed)}")
    if skipped: print(f"     {GRAY}↪ {lbl_skipped}:{RESET} {', '.join(skipped)}")
    if not fixed and not skipped: print(f"     {GRAY}{lbl_no_action}{RESET}")
    print()

print(f"{GRAY}{lbl_total}: {len(records)} {lbl_entries} | ~/.tdoc/report.json{RESET}")
PYEOF
else
  print_warn "$(t L_HISTORY_NO_PYTHON)"; echo; cat "$REPORT_FILE"
fi

echo; print_info "$(t L_HISTORY_CLEAR_HINT)"
