#!/data/data/com.termux/files/usr/bin/bash
# Auto bump TDOC version

VERSION_FILE="$TDOC_ROOT/core/version.sh"
DATE=$(date +%Y-%m-%d)

# Read current version
source "$VERSION_FILE"

# Split version
IFS='.' read -r MAJOR MINOR PATCH <<< "$TDOC_VERSION"

# Increment patch version
PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update version file
sed -i "s/^TDOC_VERSION=.*/TDOC_VERSION=\"$NEW_VERSION\"/" "$VERSION_FILE"

# Update CHANGELOG
sed -i "0,/## \[Unreleased\]/s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $DATE/" "$TDOC_ROOT/CHANGELOG.md"

echo "✅ TDOC version bumped: $TDOC_VERSION → $NEW_VERSION"
