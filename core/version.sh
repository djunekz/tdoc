#!/bin/bash
# ==============================
# TDOC Version (Central Source)
# ==============================

TDOC_NAME="tdoc"
TDOC_VERSION="1.0.5"
TDOC_CODENAME="stable"
TDOC_BUILD_DATE="2026-01-16"

export TDOC_NAME
export TDOC_VERSION
export TDOC_CODENAME
export TDOC_BUILD_DATE

tdoc_version_string() {
  echo "$TDOC_NAME v$TDOC_VERSION ($TDOC_CODENAME)"
}
