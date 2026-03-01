#!/usr/bin/env bash
# TDOC — Repository Security Logic

REPO_FILE="$PREFIX/etc/apt/sources.list"
KEYRING="$PREFIX/share/keyrings/termux-archive-keyring.gpg"
APT_LISTS="$PREFIX/var/lib/apt/lists"

scan_repo_security() {
    WARNINGS=()
    DANGERS=()
    SECURITY_STATE="OK"

    if [[ ! -f "$REPO_FILE" ]]; then
        DANGERS+=("sources.list not found")
        SECURITY_STATE="BROKEN"
        return 1
    fi

    if [[ ! -f "$KEYRING" ]]; then
        WARNINGS+=("keyring not found: $KEYRING")
        SECURITY_STATE="WARN"
    fi

    if [[ ! -d "$APT_LISTS" ]]; then
        WARNINGS+=("apt lists directory not found")
        SECURITY_STATE="WARN"
    fi

    local broken=0

    while IFS= read -r line; do
        [[ "$line" =~ ^# || -z "$line" ]] && continue

        local url
        url=$(echo "$line" | awk '{print $2}')
        [[ "$url" =~ ^https?:// ]] || continue

        local host
        host=$(echo "$url" | awk -F/ '{print $3}')

        local release
        release=$(ls "$APT_LISTS" 2>/dev/null | grep "$host" | grep "_Release$" | head -n1)

        if [[ -z "$release" ]]; then
            WARNINGS+=("no release file for: $host")
            broken=1
            continue
        fi

        release="$APT_LISTS/$release"
        sig="${release}.gpg"

        if [[ ! -f "$sig" ]]; then
            DANGERS+=("missing signature for: $host")
            broken=1
            continue
        fi

        if ! gpg --keyring "$KEYRING" --verify "$sig" "$release" >/dev/null 2>&1; then
            DANGERS+=("signature verification failed: $host")
            broken=1
        fi

    done < "$REPO_FILE"

    if [[ "$broken" -eq 1 ]]; then
        SECURITY_STATE="BROKEN"
        return 1
    fi

    return 0
}

export -f scan_repo_security
