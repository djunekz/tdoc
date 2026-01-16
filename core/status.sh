#!/bin/bash

echo -e "🩺 Termux Doctor v1.0\n"

issues=0

while IFS='=' read -r key value; do
  case "$value" in
    OK)
      echo -e "$icon_ok $key"
      ;;
    PARTIAL)
      echo -e "$icon_warn $key"
      issues=$((issues+1))
      ;;
    BROKEN)
      echo -e "$icon_err $key"
      issues=$((issues+1))
      ;;
  esac
done < "$STATE_FILE"

echo ""
if [ "$issues" -gt 0 ]; then
  echo -e "$issues issue(s) detected"
  echo "Run: tdoc fix"
else
  echo -e "${COLOR_OK}System healthy${COLOR_RESET}"
fi
