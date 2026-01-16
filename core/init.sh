#!/bin/bash
STATE_FILE="$TDOC_ROOT/data/state.env"
> "$STATE_FILE"

export STATE_FILE

COLOR_OK="\e[32m"
COLOR_WARN="\e[33m"
COLOR_ERR="\e[31m"
COLOR_RESET="\e[0m"

icon_ok="🟢"
icon_warn="🟡"
icon_err="🔴"

source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/explain_repo.sh"
source "$TDOC_ROOT/core/explain_storage.sh"
source "$TDOC_ROOT/core/explain_python.sh"
source "$TDOC_ROOT/core/explain_node.sh"
