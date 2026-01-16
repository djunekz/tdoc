#!/data/data/com.termux/files/usr/bin/bash

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/repo_security.sh"

print_header "🛡 TDOC Repository Security Scan"
echo

scan_repo_security

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
esac

echo

for w in "${WARNINGS[@]}"; do
  print_warn "$w"
done

for d in "${DANGERS[@]}"; do
  print_err "$d"
done

if [ "${#DANGERS[@]}" -gt 0 ]; then
  echo
  print_info "Suggested action: tdoc fix"
fi
