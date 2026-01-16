explain_node() {
  echo "🔴 NodeJS Environment Issue ($1)"
  echo
  echo "Reason:"
  echo "NodeJS is not installed or broken."
  echo
  echo "Impact:"
  echo "- npm / yarn will fail"
  echo "- Node-based tools cannot run"
  echo
  echo "Recommended Fix:"
  echo "→ Run: pkg install nodejs"
}
