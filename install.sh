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

echo "Installing TDOC (Termux Doctor)"

if [[ ! -w "$PREFIX_PATH/bin" ]]; then
  echo "❌ No write permission to $PREFIX_PATH/bin"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.tdoc"
mkdir -p "$MAN_DIR"
mkdir -p "$STATE_DIR"

cp -r core    "$INSTALL_DIR/"
cp -r modules "$INSTALL_DIR/"
cp -r data    "$INSTALL_DIR/"
cp -r lang    "$INSTALL_DIR/"

if [[ -f "man/tdoc.1" ]]; then
  install -Dm644 man/tdoc.1 "$MAN_DIR/tdoc.1"
  echo "📘 Man page installed: man tdoc"
else
  echo "⚠️  man/tdoc.1 not found, skipping"
fi

install -Dm755 tdoc "$INSTALL_DIR/tdoc"
ln -sf "$INSTALL_DIR/tdoc" "$BIN_PATH"
chmod +x "$BIN_PATH"

if [[ -f "VERSION" ]]; then
  install -Dm644 VERSION "$INSTALL_DIR/VERSION"
else
  echo "⚠️  VERSION file not found, version info may show 'unknown'"
fi

find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ TDOC (Termux Doctor) installed successfully"
echo
echo "Available commands:"
echo "  tdoc scan              — full system scan"
echo "  tdoc repo-scan         — scan bugs/syntax errors in current project folder"
echo "  tdoc diagnose          — diagnose any error by pasting it interactively"
echo "  tdoc diagnose -f <log> — diagnose from a log file"
echo "  tdoc status            — show last scan status"
echo "  tdoc fix               — interactive fix wizard"
echo "  tdoc fix --preview     — preview fixes (dry-run)"
echo "  tdoc fix --auto        — automatic fix"
echo "  tdoc check <package>   — check any package"
echo "  tdoc history           — view operation history"
echo "  tdoc benchmark         — measure performance"
echo "  tdoc doctor --live     — real-time monitoring"
echo "  tdoc lang set <code>   — set display language (en, id)"
echo "  tdoc help              — show full help"
