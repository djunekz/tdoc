#!/bin/bash

echo -e "🧠 Termux Doctor — Explanation Mode\n"

while IFS='=' read -r key value; do
  if [ "$value" = "OK" ]; then
    continue
  fi

  case "$key" in
    Repository)
      explain_repo "$value"
      ;;
    Storage)
      explain_storage "$value"
      ;;
    Python)
      explain_python "$value"
      ;;
    NodeJS)
      explain_node "$value"
      ;;
  esac

  echo "--------------------------------"
done < "$STATE_FILE"
