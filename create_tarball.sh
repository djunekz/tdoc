#!/data/data/com.termux/files/usr/bin/bash
set -e

# ==============================
# TDOC Release Tarball Builder
# ==============================

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load version (single source of truth)
source "$ROOT_DIR/core/version.sh"

ARCHIVE="tdoc-v${TDOC_VERSION}.tar.gz"

echo "📦 Building TDOC release: $ARCHIVE"
echo

# Safety check
[ -z "$TDOC_VERSION" ] && {
  echo "❌ TDOC_VERSION not set"
  exit 1
}

# Clean old archive if exists
rm -f "$ARCHIVE"

# Create tarball
tar \
  --exclude=".git" \
  --exclude=".github" \
  --exclude="node_modules" \
  --exclude="*.log" \
  --exclude="*.tmp" \
  --exclude="*create_tarball.sh" \
  -czvf "$ARCHIVE" \
  .

echo
echo "✅ Tarball created successfully"
echo "📄 File: $ARCHIVE"
echo

# Quick validation
echo "🔍 Verifying archive contents:"
tar -tzf "$ARCHIVE" | head -n 15

echo
echo "🚀 Ready to upload to GitHub Release"
