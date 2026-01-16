#!/data/data/com.termux/files/usr/bin/bash

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/bump_version.sh"
source "$TDOC_ROOT/core/update_config.sh"

# ------------------
# CHECK MODE
# ------------------
if [ "$1" = "--check" ]; then
    source "$TDOC_ROOT/core/update_check.sh"
    exit 0
fi

print_header "⬆️ TDOC Update"
echo

# fetch release info
RELEASE_JSON=$(curl -s "$TDOC_RELEASE_API")
LATEST_VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | cut -d '"' -f4)
ASSET_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$TDOC_ASSET_NAME" | cut -d '"' -f4)

if [ -z "$LATEST_VERSION" ] || [ -z "$ASSET_URL" ]; then
    print_warn "Failed to fetch update info"
    exit 1
fi

echo "Current version : $TDOC_VERSION"
echo "Latest version  : $LATEST_VERSION"
echo

if [ "$TDOC_VERSION" = "$LATEST_VERSION" ]; then
    print_ok "Already up to date"
    exit 0
fi

read -p "Update to $LATEST_VERSION ? [y/N] " confirm
[ "$confirm" != "y" ] && exit 0

TMP_DIR="/tmp/tdoc-update"
mkdir -p "$TMP_DIR"

# ------------------
# Download update
# ------------------
spinner_start "Downloading update"
curl -L "$ASSET_URL" -o "$TMP_DIR/tdoc.tar.gz" >/dev/null 2>&1
spinner_stop

# ------------------
# Install update
# ------------------
spinner_start "Installing update"
tar -xzf "$TMP_DIR/tdoc.tar.gz" -C "$TMP_DIR" >/dev/null 2>&1
cp -r "$TMP_DIR/tdoc/"* "$TDOC_ROOT/../"
spinner_stop

# -----------------------------
# Auto bump version & CHANGELOG
# -----------------------------
spinner_start "Bumping version & updating CHANGELOG"
bash "$TDOC_ROOT/core/bump_version.sh"
spinner_stop

# -----------------------------
# Git commit & tag (if repo)
# -----------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    spinner_start "Committing version bump to GitHub"
    git add "$TDOC_ROOT/core/version.sh" "$TDOC_ROOT/CHANGELOG.md"
    git commit -m "chore: bump version to $TDOC_VERSION" >/dev/null 2>&1
    git tag -a "v$TDOC_VERSION" -m "Release $TDOC_VERSION" >/dev/null 2>&1
    git push --follow-tags >/dev/null 2>&1
    spinner_stop
else
    print_warn "Not a git repo: skipping commit/tag"
fi

print_ok "✅ TDOC updated to $LATEST_VERSION"
