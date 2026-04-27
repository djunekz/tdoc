#!/usr/bin/env bash
# ==============================
# TDOC — Repository Security UI
# ==============================
# UI wrapper only.
# No system modification.
# Relies solely on exit code from core logic.
# ==============================

set -euo pipefail

: "${TDOC_ROOT:?TDOC_ROOT is not set}"

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/repo_security.sh"

print_header "🛡 TDOC Repository Security Scan"
echo

if scan_repo_security; then
    print_ok "Repository metadata and signatures are valid"
    STATE="OK"
else
    print_err "Repository metadata or signature verification failed"
    STATE="BROKEN"
fi

echo
print_info "State   : $STATE"
print_info "Checked : $(date -Iseconds)"
