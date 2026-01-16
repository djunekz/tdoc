explain_storage() {
  echo "🟡 Storage Access Issue ($1)"
  echo
  echo "Reason:"
  echo "Termux does not have access to shared storage."
  echo
  echo "Impact:"
  echo "- Cannot access /sdcard"
  echo "- Scripts relying on files may fail"
  echo
  echo "Recommended Fix:"
  echo "→ Run: termux-setup-storage"
}
