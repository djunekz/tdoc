#!/usr/bin/env bash
# TDOC — Repository Security Logic

KEYRING="$PREFIX/share/keyrings/termux-archive-keyring.gpg"
APT_LISTS="$PREFIX/var/lib/apt/lists"

scan_repo_security() {
    WARNINGS=()
    DANGERS=()
    SECURITY_STATE="OK"

    if [[ ! -d "$APT_LISTS" ]]; then
        WARNINGS+=("apt lists directory not found — run: apt update")
        SECURITY_STATE="WARN"
        return 0
    fi

    local inrelease_files=()
    while IFS= read -r -d '' f; do
        inrelease_files+=("$f")
    done < <(find "$APT_LISTS" -maxdepth 1 -name "*InRelease" -print0 2>/dev/null)

    if [[ ${#inrelease_files[@]} -eq 0 ]]; then
        WARNINGS+=("no InRelease files found — run: apt update")
        SECURITY_STATE="WARN"
        return 0
    fi

    local broken=0

    for inrelease in "${inrelease_files[@]}"; do
        local fname
        fname=$(basename "$inrelease")

        if [[ ! -s "$inrelease" ]]; then
            WARNINGS+=("empty InRelease file: $fname")
            broken=1
            continue
        fi

        if ! grep -q "BEGIN PGP" "$inrelease" 2>/dev/null; then
            WARNINGS+=("InRelease not signed: $fname")
            broken=1
            continue
        fi

        if [[ -f "$KEYRING" ]]; then
            if ! gpg --no-default-keyring \
                     --keyring "$KEYRING" \
                     --verify "$inrelease" >/dev/null 2>&1; then
                WARNINGS+=("signature unverified (non-fatal): $fname")
            fi
        fi
    done

    if [[ "$broken" -eq 1 ]]; then
        SECURITY_STATE="BROKEN"
        return 1
    fi

    return 0
}

export -f scan_repo_security
