<<<<<<< HEAD
#!/usr/bin/env bash
=======
repo() {
>>>>>>> 57edac796ac842f9e4a0787f09d65c774a9a2d90
  if grep -q "packages.termux.dev" $PREFIX/etc/apt/sources.list 2>/dev/null; then
    echo "Repository=OK" >> "$STATE_FILE"
  else
    echo "Repository=BROKEN" >> "$STATE_FILE"
  fi
}
