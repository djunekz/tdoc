#!/data/data/com.termux/files/usr/bin/bash

set -e

PREFIX_PATH="$PREFIX"
INSTALL_DIR="$PREFIX_PATH/lib/tdoc"
BIN_PATH="$PREFIX_PATH/bin/tdoc"

echo "🚀 Installing TDOC..."

# Permission check
if [ ! -w "$PREFIX_PATH/bin" ]; then
  echo "❌ No permission to write to $PREFIX_PATH"
  exit 1
fi

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.tdoc"

# Copy files
cp -r core "$INSTALL_DIR/"
cp tdoc "$INSTALL_DIR/tdoc"

# Symlink binary
ln -sf "$INSTALL_DIR/tdoc" "$BIN_PATH"

# Permission
chmod +x "$INSTALL_DIR/tdoc"
chmod +x "$BIN_PATH"
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ TDOC installed successfully"
echo
echo "Usage:"
echo "  tdoc"
echo "  tdoc status"
echo "  tdoc fix --auto"
echo "  tdoc doctor --json"
