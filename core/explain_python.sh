explain_python() {
  echo "🔴 Python Environment Issue ($1)"
  echo
  echo "Reason:"
  echo "Python is missing or not properly installed."
  echo
  echo "Impact:"
  echo "- pip install will fail"
  echo "- Python scripts cannot run"
  echo
  echo "Recommended Fix:"
  echo "→ Run: pkg install python"
}
