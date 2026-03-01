#!/usr/bin/env bash
#
# TDOC Installer
#

set -euo pipefail

PREFIX_PATH="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_DIR="$PREFIX_PATH/lib/tdoc"
BIN_PATH="$PREFIX_PATH/bin/tdoc"
MAN_DIR="$PREFIX_PATH/share/man/man1"
STATE_DIR="$PREFIX_PATH/var/lib/tdoc"

echo "🚀 Installing TDOC..."

# --- permission check ---
if [[ ! -w "$PREFIX_PATH/bin" ]]; then
  echo "❌ No permission to write to $PREFIX_PATH/bin"
  exit 1
fi

# --- create directories ---
mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.tdoc"
mkdir -p "$MAN_DIR"
mkdir -p "$STATE_DIR"

# --- copy files ---
cp -r core "$INSTALL_DIR/"
cp -r modules "$INSTALL_DIR/"
cp -r data "$INSTALL_DIR/"
cp tdoc "$INSTALL_DIR/tdoc"

# --- man page ---
if [[ -f "man/tdoc.1" ]]; then
  install -Dm644 man/tdoc.1 "$MAN_DIR/tdoc.1"
  echo "📘 Man page installed: man tdoc"
else
  echo "⚠️  Warning: man/tdoc.1 not found, skipping"
fi

# --- symlink binary ---
ln -sf "$INSTALL_DIR/tdoc" "$BIN_PATH"

# --- permissions ---
chmod +x "$INSTALL_DIR/tdoc"
chmod +x "$BIN_PATH"
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ TDOC installed successfully"
echo
echo "Usage:"
echo "  tdoc scan"
echo "  tdoc status"
echo "  tdoc fix --auto"
echo "  tdoc doctor --json"
echo "  tdoc security"
echo "  man tdoc"
