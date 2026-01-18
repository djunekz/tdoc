#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Repository Security Scanner (Compliant)
# ==============================
# Fully read-only; safe for Termux-packages
# Signature verification of repo metadata
# ==============================

STATE_FILE="$PREFIX/var/lib/tdoc/state.env"
mkdir -p "$(dirname "$STATE_FILE")"

REPO_FILE="$PREFIX/etc/apt/sources.list"
KEYRING="/usr/share/keyrings/termux-archive-keyring.gpg"

SECURITY_STATE="OK"

# -----------------------
# Helper: verify Release signature
# -----------------------
verify_repo_signature() {
    local repo_url="$1"
    local repo_name
    repo_name=$(basename "$repo_url")
    local release_file="/var/lib/apt/lists/${repo_name}_Release"
    local sig_file="${release_file}.gpg"

    if [[ -f "$release_file" && -f "$sig_file" ]]; then
        if gpg --keyring "$KEYRING" --verify "$sig_file" "$release_file" >/dev/null 2>&1; then
            echo "Repository=OK" >> "$STATE_FILE"
            echo -e " [✔] Repository ($repo_name)"
        else
            echo "Repository=BROKEN" >> "$STATE_FILE"
            echo -e " [✖] Repository ($repo_name) — invalid signature"
            SECURITY_STATE="BROKEN"
        fi
    else
        echo "Repository=BROKEN" >> "$STATE_FILE"
        echo -e " [✖] Repository ($repo_name) — missing metadata"
        SECURITY_STATE="BROKEN"
    fi
}

# -----------------------
# Main scan
# -----------------------
echo "🔒 TDOC — Repository Security Scan"

if [[ ! -f "$REPO_FILE" ]]; then
    echo " [✖] sources.list missing"
    echo "Repository=BROKEN" >> "$STATE_FILE"
    SECURITY_STATE="BROKEN"
    exit 1
fi

# Parse all repos
while read -r line; do
    [[ "$line" =~ ^# || -z "$line" ]] && continue
    url=$(echo "$line" | awk '{print $2}')
    [[ "$url" =~ ^https?:// ]] || continue
    verify_repo_signature "$url"
done < "$REPO_FILE"

# -----------------------
# Summary
# -----------------------
echo
echo "State   : $SECURITY_STATE"
echo "Scan completed ✅"
