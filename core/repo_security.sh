#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# TDOC Repo Security Scanner
# ==============================

REPO_FILE="$PREFIX/etc/apt/sources.list"
SECURITY_STATE="OK"
WARNINGS=()
DANGERS=()

OFFICIAL_DOMAINS=(
  "packages.termux.dev"
  "packages-cf.termux.dev"
)

domain_allowed() {
  local domain="$1"
  for d in "${OFFICIAL_DOMAINS[@]}"; do
    [[ "$domain" == *"$d"* ]] && return 0
  done
  return 1
}

scan_repo_security() {

  if [ ! -f "$REPO_FILE" ]; then
    DANGERS+=("sources.list_missing")
    SECURITY_STATE="DANGER"
    return
  fi

  while read -r line; do
    [[ "$line" =~ ^# || -z "$line" ]] && continue

    url=$(echo "$line" | awk '{print $2}')
    domain=$(echo "$url" | sed -E 's#https?://([^/]+)/?.*#\1#')

    # HTTP check
    if [[ "$url" == http://* ]]; then
      WARNINGS+=("repo_http:$domain")
      SECURITY_STATE="WARNING"
    fi

    # Domain whitelist check
    if ! domain_allowed "$domain"; then
      DANGERS+=("unofficial_domain:$domain")
      SECURITY_STATE="DANGER"
    fi

  done < "$REPO_FILE"

  # Release file check
  if ! apt update >/dev/null 2>&1; then
    WARNINGS+=("apt_update_failed")
    [[ "$SECURITY_STATE" == "OK" ]] && SECURITY_STATE="WARNING"
  fi

  # Key check
  apt-key list >/dev/null 2>&1 || {
    WARNINGS+=("apt_key_issue")
    [[ "$SECURITY_STATE" == "OK" ]] && SECURITY_STATE="WARNING"
  }
}
