#!/usr/bin/env bash
# ==============================
# TDOC — i18n Engine (Translator)
# ==============================

t() {
  local key="$1"
  local val="${!key:-}"
  if [[ -n "$val" ]]; then
    echo "$val"
  else
    echo "$key"
  fi
}

load_lang() {
  local lang=""

  if [[ -n "${TDOC_LANG:-}" ]]; then
    lang="$TDOC_LANG"
  fi

  if [[ -z "$lang" && -f "$HOME/.tdoc/config" ]]; then
    local saved
    saved=$(grep '^TDOC_LANG=' "$HOME/.tdoc/config" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
    [[ -n "$saved" ]] && lang="$saved"
  fi

  if [[ -z "$lang" ]]; then
    local sys="${LANG:-${LC_ALL:-}}"
    if [[ "$sys" == id_ID* ]]; then
      lang="id"
    else
      lang="en"
    fi
  fi

  lang="${lang,,}"

  local lang_file="${TDOC_ROOT}/lang/${lang}.sh"
  if [[ -f "$lang_file" ]]; then
    source "$lang_file"
  else
    source "${TDOC_ROOT}/lang/en.sh"
    lang="en"
  fi

  export TDOC_LANG="$lang"
}
