<<<<<<< HEAD
#!/usr/bin/env bash
=======
node() {
>>>>>>> 57edac796ac842f9e4a0787f09d65c774a9a2d90
  command -v node >/dev/null && echo "NodeJS=OK" >> "$STATE_FILE" || echo "NodeJS=BROKEN" >> "$STATE_FILE"
}
