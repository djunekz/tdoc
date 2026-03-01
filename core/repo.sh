repo() {
  local found=0

  if grep -q "packages.termux.dev" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
    found=1
  fi

  if [[ -d "$PREFIX/etc/apt/sources.list.d" ]]; then
    if grep -rq "packages.termux.dev" "$PREFIX/etc/apt/sources.list.d/" 2>/dev/null; then
      found=1
    fi
  fi

  if [[ "$found" -eq 1 ]]; then
    echo "Repository=OK" >> "$STATE_FILE"
  else
    echo "Repository=BROKEN" >> "$STATE_FILE"
  fi
}
