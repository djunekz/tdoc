node() {
  command -v node >/dev/null && echo "NodeJS=OK" >> "$STATE_FILE" || echo "NodeJS=BROKEN" >> "$STATE_FILE"
}
