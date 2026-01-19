#!/usr/bin/env bash
#
# TDOC Installer
#

set -euo pipefail

PREFIX_PATH="$PREFIX"
INSTALL_DIR="$PREFIX_PATH/lib/tdoc"
BIN_PATH="$PREFIX_PATH/bin/tdoc"
MAN_DIR="$PREFIX_PATH/share/man/man1"

echo "🚀 Installing TDOC..."

# --- permission check ---------------------------------------

if [[ ! -w "$PREFIX_PATH/bin" ]]; then
  echo "❌ No permission to write to $PREFIX_PATH/bin"
  exit 1
fi

# --- create directories ------------------------------------

mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.tdoc"
mkdir -p "$MAN_DIR"

# --- copy core files ---------------------------------------

cp -r core "$INSTALL_DIR/"
cp tdoc "$INSTALL_DIR/tdoc"

# --- install man page --------------------------------------

if [[ -f "man/tdoc.1" ]]; then
  install -Dm644 man/tdoc.1 "$MAN_DIR/tdoc.1"
  echo "📘 Man page installed: man tdoc"
else
  echo "⚠️  Warning: man/tdoc.1 not found, skipping man page install"
fi

# --- symlink binary ----------------------------------------

ln -sf "$INSTALL_DIR/tdoc" "$BIN_PATH"

# --- permissions -------------------------------------------

chmod +x "$INSTALL_DIR/tdoc"
chmod +x "$BIN_PATH"
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# --- done --------------------------------------------------

echo "✅ TDOC installed successfully"
echo
echo "Usage:"
echo "  tdoc"
echo "  tdoc status"
echo "  tdoc fix --auto"
echo "  tdoc doctor --json"
echo "  man tdoc"
