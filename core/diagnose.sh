#!/usr/bin/env bash
# ==============================
# TDOC — diagnose
# Match a raw error message / repo-scan output to a
# known issue, explain it, and offer to fix it.
#
# Usage:
#   tdoc diagnose "error message"   ← single-line arg
#   tdoc diagnose                   ← interactive multi-line prompt
#   tdoc diagnose --last            ← diagnose last repo-scan output
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/ai_explain.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
REPO_SCAN_STATE="${HOME}/.tdoc/repo_scan_last.txt"

BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

_diag_header() {
  echo
  echo -e "${CYAN}${BORDER}${RESET}"
  echo -e "${CYAN}🩺 $(t L_DIAG_HEADER)${RESET}"
  echo -e "${CYAN}${BORDER}${RESET}"
  echo
}

_diag_match_line() {
  local s="$1"

  # ── repo-scan specific ──────────────────────────────────────────────────────
  echo "$s" | grep -qiE "unpinned depend|consider pinning|unpinned.*requirements|unpinned.*package\.json" \
    && echo "UnpinnedDep" && return
  echo "$s" | grep -qiE "unreferenced.*function|defined.*never called|unref.*func" \
    && echo "UnrefFunc" && return
  echo "$s" | grep -qiE "unreferenced.*module|never sourced|unref.*module" \
    && echo "UnrefModule" && return
  echo "$s" | grep -qiE "undefined.*call|called.*never defined|undef.*call" \
    && echo "UndefCall" && return
  echo "$s" | grep -qiE "broken.*link|\.md.*broken link" \
    && echo "BrokenMdLink" && return
  echo "$s" | grep -qiE "traceback|error:|exception:|fatal|segmentation fault" \
    && echo "Traceback" && return
  echo "$s" | grep -qiE "invalid json" \
    && echo "InvalidJSON" && return
  echo "$s" | grep -qiE "invalid yaml|yaml.*error|mapping.*values.*not allowed" \
    && echo "InvalidYAML" && return
  echo "$s" | grep -qiE "invalid toml" \
    && echo "InvalidTOML" && return
  echo "$s" | grep -qiE "syntaxerror|indentationerror|syntax.*error.*\.py|\.py.*line [0-9]" \
    && echo "PythonSyntax" && return
  echo "$s" | grep -qiE "makefile.*space|recipe.*separator|missing separator" \
    && echo "MakefileSpace" && return

  # ── dpkg / apt ──────────────────────────────────────────────────────────────
  echo "$s" | grep -qiE "dpkg was interrupted|you must manually run.*dpkg|run.*dpkg.*--configure" \
    && echo "DpkgHalfInstalled" && return
  echo "$s" | grep -qiE "sub-process.*dpkg.*returned error|sub-process.*usr/bin/dpkg|dpkg returned error code" \
    && echo "DpkgHalfInstalled" && return
  echo "$s" | grep -qiE "unable to lock|could not get lock|lock.*var/lib/dpkg|another process.*using" \
    && echo "DpkgLock" && return
  echo "$s" | grep -qiE "half-installed|half-configured" \
    && echo "DpkgHalfInstalled" && return
  echo "$s" | grep -qiE "reinst-required|reinstallation required|ghost package" \
    && echo "DpkgReinstRequired" && return
  echo "$s" | grep -qiE "warning.*files list.*missing|files list file.*for package" \
    && echo "DpkgMissingFilesList" && return
  echo "$s" | grep -qiE "dpkg.*status.*corrupt|status.*database.*corrupt|cannot open.*dpkg/status" \
    && echo "DpkgStatusDB" && return
  echo "$s" | grep -qiE "unmet dep|dependency problems|broken packages|has unmet dep|apt-get install -f" \
    && echo "DpkgBrokenDeps" && return
  echo "$s" | grep -qiE "trying to overwrite|conflicts with.*package|file.*owned by" \
    && echo "DpkgFileConflicts" && return

  # ── tools ───────────────────────────────────────────────────────────────────
  echo "$s" | grep -qiE "python.*command not found|python3.*not found|no module named|modulenotfounderror|importerror" \
    && echo "Python" && return
  echo "$s" | grep -qiE "node.*command not found|nodejs.*not found|npm.*not found|cannot find module" \
    && echo "NodeJS" && return
  echo "$s" | grep -qiE "git.*command not found|git.*not found|not a git repo|fatal.*not a git" \
    && echo "Git" && return
  echo "$s" | grep -qiE "permission denied.*storage|cannot.*write.*storage|termux-setup-storage" \
    && echo "Storage" && return
  echo "$s" | grep -qiE "failed to fetch|could not resolve.*mirrors|404.*not found.*repo|gpg error|sources\.list" \
    && echo "Repository" && return

  echo "Unknown"
}

_diag_explain_repo() {
  local issue="$1"
  local CAUSES="$(t L_AI_COMMON_CAUSES)"
  local HOW="$(t L_AI_HOW_IT_WORKS)"
  local REC="$(t L_AI_RECOMMENDED)"

  case "$issue" in
    UnpinnedDep)
      echo "🔍 $(t L_DIAG_UNPINNED_TITLE)"
      echo; echo "$(t L_DIAG_UNPINNED_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_DIAG_UNPINNED_CAUSE1)"
      echo "• $(t L_DIAG_UNPINNED_CAUSE2)"
      echo; echo "$REC:"
      echo "→ $(t L_DIAG_UNPINNED_FIX1)"
      echo "→ $(t L_DIAG_UNPINNED_FIX2)"
      ;;
    UnrefFunc)
      echo "🔍 $(t L_DIAG_UNREF_FUNC_TITLE)"
      echo; echo "$(t L_DIAG_UNREF_FUNC_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_DIAG_UNREF_FUNC_CAUSE1)"
      echo "• $(t L_DIAG_UNREF_FUNC_CAUSE2)"
      echo; echo "$REC:"
      echo "→ $(t L_DIAG_UNREF_FUNC_FIX)"
      ;;
    UnrefModule)
      echo "🔍 $(t L_DIAG_UNREF_MOD_TITLE)"
      echo; echo "$(t L_DIAG_UNREF_MOD_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_DIAG_UNREF_MOD_CAUSE1)"
      echo "• $(t L_DIAG_UNREF_MOD_CAUSE2)"
      echo; echo "$REC:"
      echo "→ $(t L_DIAG_UNREF_MOD_FIX)"
      ;;
    UndefCall)
      echo "🔍 $(t L_DIAG_UNDEF_CALL_TITLE)"
      echo; echo "$(t L_DIAG_UNDEF_CALL_DESC)"
      echo; echo "$CAUSES:"
      echo "• $(t L_DIAG_UNDEF_CALL_CAUSE1)"
      echo "• $(t L_DIAG_UNDEF_CALL_CAUSE2)"
      echo; echo "$REC:"
      echo "→ $(t L_DIAG_UNDEF_CALL_FIX)"
      ;;
    BrokenMdLink)
      echo "🔍 $(t L_DIAG_MD_LINK_TITLE)"
      echo; echo "$(t L_DIAG_MD_LINK_DESC)"
      echo; echo "$REC:"; echo "→ $(t L_DIAG_MD_LINK_FIX)"
      ;;
    Traceback)
      echo "🔍 $(t L_DIAG_TRACEBACK_TITLE)"
      echo; echo "$(t L_DIAG_TRACEBACK_DESC)"
      echo; echo "$REC:"; echo "→ $(t L_DIAG_TRACEBACK_FIX)"
      ;;
    PythonSyntax)
      echo "🔍 $(t L_DIAG_PY_SYNTAX_TITLE)"
      echo; echo "$(t L_DIAG_PY_SYNTAX_DESC)"
      echo; echo "$REC:"; echo "→ python3 -m py_compile <file.py>"
      ;;
    InvalidJSON)
      echo "🔍 $(t L_DIAG_JSON_TITLE)"
      echo; echo "$(t L_DIAG_JSON_DESC)"
      echo; echo "$REC:"; echo "→ python3 -m json.tool <file.json>"
      ;;
    InvalidYAML)
      echo "🔍 $(t L_DIAG_YAML_TITLE)"
      echo; echo "$(t L_DIAG_YAML_DESC)"
      echo; echo "$REC:"; echo "→ python3 -c \"import yaml; yaml.safe_load(open('<file.yml>'))\""
      ;;
    InvalidTOML)
      echo "🔍 $(t L_DIAG_TOML_TITLE)"
      echo; echo "$(t L_DIAG_TOML_DESC)"
      echo; echo "$REC:"; echo "→ python3 -c \"import tomllib; tomllib.load(open('<file.toml>','rb'))\""
      ;;
    MakefileSpace)
      echo "🔍 $(t L_DIAG_MAKEFILE_TITLE)"
      echo; echo "$(t L_DIAG_MAKEFILE_DESC)"
      echo; echo "$REC:"; echo "→ $(t L_DIAG_MAKEFILE_FIX)"
      ;;
    *)
      ai_explain "$issue"
      ;;
  esac
}

_diag_offer_fix() {
  local issue="$1"
  case "$issue" in
    DpkgLock|DpkgHalfInstalled|DpkgReinstRequired|DpkgBrokenDeps|\
    DpkgMissingFilesList|DpkgFileConflicts|DpkgStatusDB|\
    Python|NodeJS|Git|Storage)
      echo
      read -rp "$(t L_DIAG_OFFER_FIX) $(t L_PROMPT_YN): " ans
      if [[ "$ans" =~ ^[YyTt]$ ]]; then
        mkdir -p "$(dirname "$STATE_FILE")"
        { grep -v "^${issue}=" "$STATE_FILE" 2>/dev/null || true; } > "${STATE_FILE}.tmp"
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
        echo "${issue}=BROKEN" >> "$STATE_FILE"
        echo
        source "$TDOC_ROOT/core/fix.sh"
      else
        echo; print_info "$(t L_DIAG_FIX_SKIPPED)"
        print_info "$(t L_DIAG_FIX_HINT): tdoc fix"
      fi
      ;;
    UnpinnedDep|UnrefFunc|UnrefModule|UndefCall|BrokenMdLink|\
    Traceback|PythonSyntax|InvalidJSON|InvalidYAML|InvalidTOML|MakefileSpace)
      echo
      print_info "$(t L_DIAG_NO_AUTO_FIX)"
      print_info "$(t L_DIAG_RUN_SCAN): tdoc repo-scan"
      ;;
    *)
      echo; print_info "$(t L_DIAG_NO_AUTO_FIX)"
      print_info "$(t L_DIAG_RUN_SCAN): tdoc scan"
      ;;
  esac
}

_diag_process() {
  local input="$1"
  local -A _seen=()
  local found_any=false

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local lower
    lower=$(echo "$line" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    local issue
    issue=$(_diag_match_line "$lower")
    [[ "$issue" == "Unknown" ]] && continue
    [[ -n "${_seen[$issue]:-}" ]] && continue
    _seen["$issue"]=1
    found_any=true

    echo -e "${GREEN}✔ $(t L_DIAG_MATCHED): ${BOLD}${issue}${RESET}"
    echo
    echo -e "${CYAN}${BORDER}${RESET}"
    echo
    _diag_explain_repo "$issue"
    _diag_offer_fix "$issue"
    echo
    echo -e "${CYAN}${BORDER}${RESET}"
    echo
  done <<< "$input"

  if ! $found_any; then
    echo -e "${YELLOW}⚠ $(t L_DIAG_NO_MATCH)${RESET}"
    echo
    print_info "$(t L_DIAG_NO_MATCH_HINT1)"
    print_info "$(t L_DIAG_NO_MATCH_HINT2): tdoc scan"
    print_info "$(t L_DIAG_NO_MATCH_HINT3): https://github.com/djunekz/tdoc/issues"
    echo
  fi
}

_diag_run() {
  _diag_header

  if [[ "${1:-}" == "-f" ]]; then
    local file="${2:-}"
    if [[ -z "$file" ]]; then
      print_err "$(t L_DIAG_NO_FILE)"
      print_info "Usage: tdoc diagnose -f <logfile>"
      exit 1
    fi
    if [[ ! -f "$file" ]]; then
      print_err "$(t L_DIAG_FILE_NOT_FOUND): $file"
      exit 1
    fi
    echo -e "${BOLD}$(t L_DIAG_FROM_FILE): ${file}${RESET}"
    echo
    spinner_start "$(t L_DIAG_ANALYZING)..."
    sleep 0.3
    spinner_stop
    _diag_process "$(cat "$file")"
    return
  fi

  if [[ "${1:-}" == "--last" ]]; then
    if [[ ! -f "$REPO_SCAN_STATE" || ! -s "$REPO_SCAN_STATE" ]]; then
      print_err "$(t L_DIAG_NO_LAST_SCAN)"
      print_info "$(t L_DIAG_RUN_SCAN): tdoc repo-scan"
      exit 1
    fi
    echo -e "${BOLD}$(t L_DIAG_FROM_LAST_SCAN):${RESET}"
    echo -e "  ${GRAY}$(cat "$REPO_SCAN_STATE" | head -5)${RESET}"
    [[ $(wc -l < "$REPO_SCAN_STATE") -gt 5 ]] && \
      echo -e "  ${GRAY}... (+$(($(wc -l < "$REPO_SCAN_STATE")-5)) more lines)${RESET}"
    echo
    spinner_start "$(t L_DIAG_ANALYZING)..."
    sleep 0.3
    spinner_stop
    _diag_process "$(cat "$REPO_SCAN_STATE")"
    return
  fi

  if [[ $# -gt 0 ]]; then
    local raw_input="$*"
    echo -e "${BOLD}$(t L_DIAG_INPUT_LABEL):${RESET}"
    echo -e "  ${GRAY}\"${raw_input}\"${RESET}"
    echo
    spinner_start "$(t L_DIAG_ANALYZING)..."
    sleep 0.3
    spinner_stop
    _diag_process "$raw_input"
    return
  fi

  echo -e "${BOLD}$(t L_DIAG_PASTE_PROMPT)${RESET}"
  echo -e "${GRAY}$(t L_DIAG_PASTE_HINT)${RESET}"
  echo -e "${GRAY}$(t L_DIAG_PASTE_END)${RESET}"
  echo

  local lines="" line
  while IFS= read -r line; do
    [[ -z "$line" ]] && break
    lines+="$line"$'\n'
  done

  if [[ -z "$lines" ]]; then
    print_err "$(t L_DIAG_EMPTY_INPUT)"
    exit 1
  fi

  echo
  echo -e "${BOLD}$(t L_DIAG_INPUT_LABEL):${RESET}"
  local count; count=$(echo "$lines" | wc -l)
  echo "$lines" | head -2 | while IFS= read -r l; do
    echo -e "  ${GRAY}$l${RESET}"
  done
  [[ $count -gt 2 ]] && echo -e "  ${GRAY}... (+$((count-2)) more lines)${RESET}"
  echo

  spinner_start "$(t L_DIAG_ANALYZING)..."
  sleep 0.3
  spinner_stop
  _diag_process "$lines"
}

_diag_run "$@"
