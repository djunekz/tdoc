#!/usr/bin/env bash
  command -v python >/dev/null && echo "Python=OK" >> "$STATE_FILE" || echo "Python=BROKEN" >> "$STATE_FILE"
}
