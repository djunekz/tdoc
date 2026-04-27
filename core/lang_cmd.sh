#!/usr/bin/env bash
# TDOC — Command: tdoc lang

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

CONFIG_FILE="$HOME/.tdoc/config"
LANG_DIR="$TDOC_ROOT/lang"
CMD="${1:-}"

_available_langs() {
  for f in "$LANG_DIR"/*.sh; do
    basename "$f" .sh
  done
}

case "$CMD" in

  set)
    NEW_LANG="${2:-}"
    LANG_FILE="$LANG_DIR/${NEW_LANG}.sh"

    if [[ -z "$NEW_LANG" ]]; then
      print_err "Usage: tdoc lang set <code>"
      echo "Available: $(_available_langs | tr '\n' ' ')"
      exit 1
    fi

    if [[ ! -f "$LANG_FILE" ]]; then
      print_err "$(t L_LANG_INVALID): $(_available_langs | tr '\n' ' ')"
      exit 1
    fi

    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [[ -f "$CONFIG_FILE" ]] && grep -q '^TDOC_LANG=' "$CONFIG_FILE"; then
      sed -i "s/^TDOC_LANG=.*/TDOC_LANG=$NEW_LANG/" "$CONFIG_FILE"
    else
      echo "TDOC_LANG=$NEW_LANG" >> "$CONFIG_FILE"
    fi

    export TDOC_LANG="$NEW_LANG"
    source "$LANG_FILE"

    print_ok "$(t L_LANG_SET): $NEW_LANG"
    print_info "$(t L_LANG_SAVED): $CONFIG_FILE"
    ;;

  list)
    echo -e "${CYAN}$(t L_LANG_CURRENT): ${BOLD}${TDOC_LANG}${RESET}"
    echo
    echo "Available:"
    for lang in $(_available_langs); do
      if [[ "$lang" == "$TDOC_LANG" ]]; then
        echo -e "  ${GREEN}✔ $lang${RESET}"
      else
        echo -e "  ${GRAY}  $lang${RESET}"
      fi
    done
    echo
    echo "Usage: tdoc lang set <code>"
    ;;

  "")
    echo -e "${CYAN}$(t L_LANG_CURRENT): ${BOLD}${TDOC_LANG}${RESET}"
    echo
    echo "Subcommands:"
    echo "  tdoc lang list       — $(t L_LANG_CURRENT)"
    echo "  tdoc lang set <code> — $(t L_LANG_SET)"
    echo
    echo "Examples:"
    echo "  tdoc lang set id"
    echo "  tdoc lang set en"
    ;;

  *)
    print_err "Unknown subcommand: tdoc lang $CMD"
    echo "Use: tdoc lang list | tdoc lang set <code>"
    exit 1
    ;;
esac
