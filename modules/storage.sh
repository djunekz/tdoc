storage() {
  if [ -d "$HOME/storage" ]; then
    echo "Storage=OK" >> "$STATE_FILE"
  else
    echo "Storage=PARTIAL" >> "$STATE_FILE"
  fi
}
