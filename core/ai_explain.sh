#!/usr/bin/env bash

ai_explain() {
  local item="$1"
  local CAUSES="$(t L_AI_COMMON_CAUSES)"
  local HOW="$(t L_AI_HOW_IT_WORKS)"
  local REC="$(t L_AI_RECOMMENDED)"

  case "$item" in
    Storage)
      echo "🔍 $(t L_AI_STORAGE_TITLE)"
      echo; echo "$(t L_AI_STORAGE_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_STORAGE_CAUSE1)"; echo "• $(t L_AI_STORAGE_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_STORAGE_HOW1)"; echo "• $(t L_AI_STORAGE_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_STORAGE_FIX)"
      ;;
    Repository)
      echo "🔍 $(t L_AI_REPO_TITLE)"
      echo; echo "$(t L_AI_REPO_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_REPO_CAUSE1)"; echo "• $(t L_AI_REPO_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_REPO_HOW1)"; echo "• $(t L_AI_REPO_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_REPO_FIX)"
      ;;
    NodeJS)
      echo "🔍 $(t L_AI_NODEJS_TITLE)"
      echo; echo "$(t L_AI_NODEJS_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_NODEJS_CAUSE1)"; echo "• $(t L_AI_NODEJS_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_NODEJS_HOW1)"; echo "• $(t L_AI_NODEJS_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_NODEJS_FIX)"
      ;;
    Python)
      echo "🔍 $(t L_AI_PYTHON_TITLE)"
      echo; echo "$(t L_AI_PYTHON_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_PYTHON_CAUSE1)"; echo "• $(t L_AI_PYTHON_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_PYTHON_HOW1)"; echo "• $(t L_AI_PYTHON_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_PYTHON_FIX)"
      ;;
    Git)
      echo "🔍 $(t L_AI_GIT_TITLE)"
      echo; echo "$(t L_AI_GIT_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_GIT_CAUSE1)"; echo "• $(t L_AI_GIT_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_GIT_HOW1)"; echo "• $(t L_AI_GIT_HOW2)"
      echo; echo "$REC:"
      echo "→ $(t L_AI_GIT_FIX1)"; echo "→ $(t L_AI_GIT_FIX2)"
      ;;
    TermuxVersion)
      echo "🔍 $(t L_AI_TERMUX_TITLE)"
      echo; echo "$(t L_AI_TERMUX_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_TERMUX_CAUSE1)"; echo "• $(t L_AI_TERMUX_CAUSE2)"
      echo; echo "$REC:"
      echo "→ $(t L_AI_TERMUX_FIX1)"; echo "→ $(t L_AI_TERMUX_FIX2)"
      ;;
    DpkgLock)
      echo "🔍 $(t L_AI_DPKG_LOCK_TITLE)"
      echo; echo "$(t L_AI_DPKG_LOCK_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_LOCK_CAUSE1)"; echo "• $(t L_AI_DPKG_LOCK_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_DPKG_LOCK_HOW1)"; echo "• $(t L_AI_DPKG_LOCK_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_LOCK_FIX)"
      ;;
    DpkgStatusDB)
      echo "🔍 $(t L_AI_DPKG_STATUS_TITLE)"
      echo; echo "$(t L_AI_DPKG_STATUS_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_STATUS_CAUSE1)"; echo "• $(t L_AI_DPKG_STATUS_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_DPKG_STATUS_HOW1)"; echo "• $(t L_AI_DPKG_STATUS_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_STATUS_FIX)"
      ;;
    DpkgHalfInstalled)
      echo "🔍 $(t L_AI_DPKG_HALF_TITLE)"
      echo; echo "$(t L_AI_DPKG_HALF_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_HALF_CAUSE1)"; echo "• $(t L_AI_DPKG_HALF_CAUSE2)"
      echo; echo "$HOW:"
      echo "• $(t L_AI_DPKG_HALF_HOW1)"; echo "• $(t L_AI_DPKG_HALF_HOW2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_HALF_FIX)"
      ;;
    DpkgReinstRequired)
      echo "🔍 $(t L_AI_DPKG_REINST_TITLE)"
      echo; echo "$(t L_AI_DPKG_REINST_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_REINST_CAUSE1)"; echo "• $(t L_AI_DPKG_REINST_CAUSE2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_REINST_FIX)"
      ;;
    DpkgBrokenDeps)
      echo "🔍 $(t L_AI_DPKG_BROKEN_TITLE)"
      echo; echo "$(t L_AI_DPKG_BROKEN_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_BROKEN_CAUSE1)"; echo "• $(t L_AI_DPKG_BROKEN_CAUSE2)"
      echo; echo "$HOW:"; echo "• $(t L_AI_DPKG_BROKEN_HOW)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_BROKEN_FIX)"
      ;;
    DpkgMissingFilesList)
      echo "🔍 $(t L_AI_DPKG_FILES_TITLE)"
      echo; echo "$(t L_AI_DPKG_FILES_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_FILES_CAUSE1)"; echo "• $(t L_AI_DPKG_FILES_CAUSE2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_FILES_FIX)"
      ;;
    DpkgFileConflicts)
      echo "🔍 $(t L_AI_DPKG_CONFLICTS_TITLE)"
      echo; echo "$(t L_AI_DPKG_CONFLICTS_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_AI_DPKG_CONFLICTS_CAUSE1)"; echo "• $(t L_AI_DPKG_CONFLICTS_CAUSE2)"
      echo; echo "$REC:"; echo "→ $(t L_AI_DPKG_CONFLICTS_FIX)"
      ;;
    *)
      echo "🔍 $(t L_AI_UNKNOWN_TITLE)"
      echo; echo "$(t L_AI_UNKNOWN_DESC)"
      echo; echo "$REC:"
      echo "→ $(t L_AI_UNKNOWN_FIX1)"; echo "→ $(t L_AI_UNKNOWN_FIX2)"
      ;;
  esac
}

ai_diagnose() { ai_explain "$1"; }
