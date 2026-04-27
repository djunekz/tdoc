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
    *)
      echo "🔍 $(t L_AI_UNKNOWN_TITLE)"
      echo; echo "$(t L_AI_UNKNOWN_DESC)"
      echo; echo "$REC:"
      echo "→ $(t L_AI_UNKNOWN_FIX1)"; echo "→ $(t L_AI_UNKNOWN_FIX2)"
      ;;
  esac
}

ai_diagnose() { ai_explain "$1"; }
