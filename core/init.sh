#!/usr/bin/env bash
# TDOC — Bootstrap: load i18n engine + lang file

[[ -n "${TDOC_INIT_DONE:-}" ]] && return 0
export TDOC_INIT_DONE=1

export TDOC_ROOT="${TDOC_ROOT:-$PREFIX/lib/tdoc}"

source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/ai_explain.sh"

load_lang
