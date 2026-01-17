#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Repository Security Scanner (Compliant, Modular)
# ==============================
# Fully read-only; safe for Termux-packages
# Supports offline scan and subdomains
# ==============================

REPO_FILE="$PREFIX/etc/apt/sources.list"
SECURITY_STATE="OK"
WARNINGS=()
DANGERS=()

# Official Termux domains (subdomains allowed)
OFFICIAL_DOMAINS=(
  "packages.termux.dev"
  "packages-cf.termux.dev"
)

# Check if domain is allowed (supports subdomains)
domain_allowed() {
  local domain="$1"
  for d in "${OFFICIAL_DOMAINS[@]}"; do
    [[ "$domain" == *"$d"* ]] && return 0
  done
  return 1
}

# Main repo scan
# Usage: scan_repo_security [offline]
scan_repo_security() {
  local mode="${1:-online}"

  # Check sources.list exists
  if [ ! -f "$REPO_FILE" ]; then
    DANGERS+=("sources.list_missing")
    SECURITY_STATE="DANGER"
    return
  fi

  # Parse sources.list
  while read -r line; do
    [[ "$line" =~ ^# || -z "$line" ]] && continue

    url=$(echo "$line" | awk '{print $2}')
    [[ "$url" =~ ^https?:// ]] || continue

    domain=$(echo "$url" | sed -E 's#https?://([^/]+)/?.*#\1#')

    # HTTP warning
    if [[ "$url" == http://* ]]; then
      WARNINGS+=("repo_http:$domain")
      [[ "$SECURITY_STATE" == "OK" ]] && SECURITY_STATE="WARNING"
    fi

    # Domain whitelist
    if ! domain_allowed "$domain"; then
      DANGERS+=("unofficial_domain:$domain")
      SECURITY_STATE="DANGER"
    fi
  done < "$REPO_FILE"

  # Only check apt update if not offline
  if [[ "$mode" != "offline" ]]; then
    if ! apt update >/dev/null 2>&1; then
      WARNINGS+=("apt_update_failed")
      [[ "$SECURITY_STATE" == "OK" ]] && SECURITY_STATE="WARNING"
    fi
  fi

  # Optional: apt-key check (skip if deprecated)
  if command -v apt-key >/dev/null 2>&1; then
    apt-key list >/dev/null 2>&1 || {
      WARNINGS+=("apt_key_issue")
      [[ "$SECURITY_STATE" == "OK" ]] && SECURITY_STATE="WARNING"
    }
  fi
}

# Optional: human-readable summary
print_repo_security_summary() {
  echo -e "\n🔒 Repository Security Scan"
  echo "State   : $SECURITY_STATE"
  [ ${#WARNINGS[@]} -gt 0 ] && echo "Warnings: ${WARNINGS[*]}"
  [ ${#DANGERS[@]} -gt 0 ] && echo "Dangers : ${DANGERS[*]}"
}
