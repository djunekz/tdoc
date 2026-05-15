#!/usr/bin/env bash
#
# TDOC Uninstaller
#

set -euo pipefail

PREFIX_PATH="$PREFIX"
INSTALL_DIR="$PREFIX_PATH/lib/tdoc"
BIN_PATH="$PREFIX_PATH/bin/tdoc"
MAN_PAGE="$PREFIX_PATH/share/man/man1/tdoc.1"
USER_DIR="$HOME/.tdoc"

echo "Uninstalling TDOC (Termux Doctor)..."

# --- remove binary -----------------------------------------

if [[ -L "$BIN_PATH" || -f "$BIN_PATH" ]]; then
  rm -f "$BIN_PATH"
  echo "✔ Removed binary: $BIN_PATH"
else
  echo "ℹ Binary not found, skipping"
fi

# --- remove core files -------------------------------------

if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  echo "✔ Removed install directory: $INSTALL_DIR"
else
  echo "ℹ Install directory not found, skipping"
fi

# --- remove man page ---------------------------------------

if [[ -f "$MAN_PAGE" ]]; then
  rm -f "$MAN_PAGE"
  echo "✔ Removed man page: man tdoc"
else
  echo "ℹ Man page not found, skipping"
fi

# --- remove user data (optional, safe) ---------------------

if [[ -d "$USER_DIR" ]]; then
  rm -rf "$USER_DIR"
  echo "✔ Removed user config: $USER_DIR"
else
  echo "ℹ User config not found, skipping"
fi

# --- done --------------------------------------------------

echo
echo "✅ TDOC uninstalled successfully"
