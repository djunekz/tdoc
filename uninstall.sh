#!/data/data/com.termux/files/usr/bin/bash

PREFIX_PATH="$PREFIX"
INSTALL_DIR="$PREFIX_PATH/lib/tdoc"
BIN_PATH="$PREFIX_PATH/bin/tdoc"

echo "🧹 Uninstalling TDOC..."

rm -rf "$INSTALL_DIR"
rm -f "$BIN_PATH"

echo "✅ TDOC removed"
echo "⚠ User data kept at ~/.tdoc"
