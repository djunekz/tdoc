<<<<<<< HEAD
#!/usr/bin/env bash
=======
storage() {
>>>>>>> 57edac796ac842f9e4a0787f09d65c774a9a2d90
  if [ -d "$HOME/storage" ]; then
    echo "Storage=OK" >> "$STATE_FILE"
  else
    echo "Storage=PARTIAL" >> "$STATE_FILE"
  fi
}
