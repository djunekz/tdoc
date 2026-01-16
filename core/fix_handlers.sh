#!/bin/bash
source "$TDOC_ROOT/core/ui.sh"

auto_fix_storage() {
  spinner_start "Fixing Storage access"
  termux-setup-storage >/dev/null 2>&1
  spinner_stop
  print_ok "Storage access ensured"
}

auto_fix_repository() {
  spinner_start "Repairing repository"
  termux-change-repo >/dev/null 2>&1
  spinner_stop
  print_ok "Repository updated"
}

auto_fix_nodejs() {
  spinner_start "Installing NodeJS"
  pkg install -y nodejs >/dev/null 2>&1
  spinner_stop
  print_ok "NodeJS installed"
}
