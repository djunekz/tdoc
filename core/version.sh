#!/usr/bin/env bash
# ============================================================
# TDOC — core/version.sh
# ============================================================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"

_VERSION_FILE="$TDOC_ROOT/VERSION"

if [[ -f "$_VERSION_FILE" ]]; then
  source "$_VERSION_FILE"

  TDOC_VERSION="${VERSION:-unknown}"
  TDOC_CODENAME="${CODENAME:-}"
  TDOC_BUILD_DATE="${BUILD_DATE:-}"
else
  TDOC_VERSION="unknown"
  TDOC_CODENAME=""
  TDOC_BUILD_DATE=""
fi

export TDOC_NAME="TDOC (Termux Doctor)"
export TDOC_VERSION
export TDOC_CODENAME
export TDOC_BUILD_DATE
