#!/bin/bash

ai_diagnose() {
  local item="$1"

  case "$item" in

    Storage)
      cat <<EOF
Problem:
• Termux storage permission not granted

Possible Causes:
• termux-setup-storage not executed
• Permission revoked by Android

Recommended Fix:
→ termux-setup-storage

Confidence:
90%
EOF
      ;;

    Repository)
      cat <<EOF
Problem:
• Package repository misconfigured

Possible Causes:
• Default repo unreachable
• Mirror outdated

Recommended Fix:
→ termux-change-repo

Confidence:
88%
EOF
      ;;

    NodeJS)
      cat <<EOF
Problem:
• NodeJS not installed or binary missing

Possible Causes:
• Package not installed
• Installation interrupted

Recommended Fix:
→ pkg install nodejs

Confidence:
92%
EOF
      ;;

    Python)
      cat <<EOF
Problem:
• Python binary missing or corrupted

Possible Causes:
• Interrupted installation
• Repository mismatch

Recommended Fix:
→ pkg reinstall python

Confidence:
85%
EOF
      ;;

    *)
      cat <<EOF
Problem:
• Unknown issue

Recommended Fix:
→ Manual inspection required

Confidence:
40%
EOF
      ;;
  esac
}
