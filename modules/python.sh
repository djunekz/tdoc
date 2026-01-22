<<<<<<< HEAD
#!/usr/bin/env bash
=======
python() {
>>>>>>> 57edac796ac842f9e4a0787f09d65c774a9a2d90
  command -v python >/dev/null && echo "Python=OK" >> "$STATE_FILE" || echo "Python=BROKEN" >> "$STATE_FILE"
}
