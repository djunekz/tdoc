explain_repo() {
  echo "🔴 Repository Issue ($1)"
  echo
  echo "Reason:"
  echo "Your Termux repository is outdated or not using official sources."
  echo
  echo "Impact:"
  echo "- Package install/update may fail"
  echo "- pkg errors are likely"
  echo
  echo "Recommended Fix:"
  echo "→ Run: termux-change-repo"
}
