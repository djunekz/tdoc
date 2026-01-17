#!/data/data/com.termux/files/usr/bin/bash

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/repo_security.sh"

print_header "🛡 TDOC Repository Security Scan"
echo

# Scan repository
scan_repo_security

# Show main state
case "$SECURITY_STATE" in
  OK)
    print_ok "Repository secure (official Termux mirror)"
    ;;
  WARNING)
    print_warn "Repository has security warnings"
    ;;
  DANGER)
    print_err "Repository is NOT SAFE"
    ;;
  *)
    print_warn "Repository state unknown"
    ;;
esac

echo

# Show detailed warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
  print_warn "Warnings:"
  for w in "${WARNINGS[@]}"; do
    echo "• $w"
  done
fi

# Show detailed dangers
if [ ${#DANGERS[@]} -gt 0 ]; then
  print_err "Dangers:"
  for d in "${DANGERS[@]}"; do
    echo "• $d"
  done
  echo
  print_info "Suggested action: tdoc fix"
fi

# Optional: timestamp
print_info "Scan completed at: $(date -Iseconds)"
