#!/usr/bin/env bash
# TDOC — Live Watch

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

INTERVAL="${1:-60}"
STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -lt 10 ]]; then
  print_err "$(t L_WATCH_MIN_INTERVAL)"; echo "$(t L_WATCH_USAGE)"; exit 1
fi

print_header "👁 $(t L_WATCH_HEADER)"
echo -e "${GRAY}$(t L_WATCH_INTERVAL): $(t L_WATCH_EVERY) ${INTERVAL} $(t L_WATCH_SECONDS) | $(t L_WATCH_INFO)${RESET}"; echo

trap 'echo; print_info "$(t L_WATCH_STOPPED)"; exit 0' INT TERM

PREV_STATE=""; ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))
  TIMESTAMP=$(date '+%H:%M:%S')
  source "$TDOC_ROOT/core/scan.sh" > /tmp/tdoc_scan_out.txt 2>&1
  CURRENT_STATE=""; [[ -f "$STATE_FILE" ]] && CURRENT_STATE=$(cat "$STATE_FILE")

  if [[ "$CURRENT_STATE" != "$PREV_STATE" && -n "$PREV_STATE" ]]; then
    echo -e "\n${RED}⚠ $(t L_WATCH_CHANGED) [${TIMESTAMP}]${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    while IFS='=' read -r key value; do
      [[ -z "$key" ]] && continue
      prev_val=$(echo "$PREV_STATE" | grep "^${key}=" | cut -d= -f2)
      if [[ "$value" != "$prev_val" ]]; then
        if [[ "$value" == "OK" ]]; then echo -e "  ${GREEN}✔ $key: $prev_val → $value${RESET}"
        else                            echo -e "  ${RED}✖ $key: $prev_val → $value${RESET}"; fi
      fi
    done < "$STATE_FILE"
    if command -v termux-notification >/dev/null 2>&1; then
      termux-notification --title "$(t L_WATCH_NOTIFY_TITLE)" \
        --content "$(t L_WATCH_NOTIFY_CONTENT)" --id "tdoc-watch" 2>/dev/null || true
    fi
  else
    ok=$(grep -c '=OK$' "$STATE_FILE" 2>/dev/null || echo 0)
    broken=$(grep -cv '=OK$' "$STATE_FILE" 2>/dev/null || echo 0)
    printf "\r${GRAY}[%s] #%d — $(t L_OK_COUNT): %d, $(t L_BROKEN_COUNT): %d | $(t L_WATCH_NEXT) %ds...${RESET}   " \
      "$TIMESTAMP" "$ITERATION" "$ok" "$broken" "$INTERVAL"
  fi

  PREV_STATE="$CURRENT_STATE"; sleep "$INTERVAL"
done
