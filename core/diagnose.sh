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
source "$TDOC_ROOT/core/diagnose_engine.sh"
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

_diag_process() {
  local input="$1"
  local found_any=false

  while IFS=$'\t' read -r issue weight; do
    [[ -z "$issue" ]] && continue
    found_any=true

    if (( weight <= DIAG_LOW_CONFIDENCE_WEIGHT )); then
      echo -e "${YELLOW}~ $(t L_DIAG_MATCHED) (low confidence): ${BOLD}${issue}${RESET}"
      echo -e "${GRAY}  Only a generic marker was found — no specific rule matched this log.${RESET}"
      echo -e "${GRAY}  Treat this as a hint, not a diagnosis. More log context may narrow it down.${RESET}"
    else
      echo -e "${GREEN}✔ $(t L_DIAG_MATCHED): ${BOLD}${issue}${RESET}"
    fi
    echo
    echo -e "${CYAN}${BORDER}${RESET}"
    echo
    _diag_explain_repo "$issue"
    _diag_offer_fix "$issue"
    echo
    echo -e "${CYAN}${BORDER}${RESET}"
    echo
  done < <(diag_classify_block "$input")

  if ! $found_any; then
    echo -e "${YELLOW}⚠ $(t L_DIAG_NO_MATCH)${RESET}"
    echo
    print_info "$(t L_DIAG_NO_MATCH_HINT1)"
    print_info "$(t L_DIAG_NO_MATCH_HINT2): tdoc scan"
    print_info "$(t L_DIAG_NO_MATCH_HINT3): https://github.com/djunekz/tdoc/issues"
    echo
  fi
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
    RustToolchain)
      echo "🔍 Missing Rust Compiler"
      echo; echo "This package needs to compile native Rust code (e.g. via maturin/setuptools-rust), but no Rust toolchain is installed in Termux."
      echo; echo "$CAUSES:"
      echo "• The 'rust' package is not installed in Termux"
      echo "• The Python package has no prebuilt wheel for Android/Termux's architecture, so pip falls back to building from source"
      echo; echo "$REC:"
      echo "→ pkg install rust"
      echo "→ then retry: pip install <package>"
      echo "→ or, if available, try: pip install --only-binary :all: <package>"
      ;;
    MissingCompiler)
      echo "🔍 Missing C/C++ Build Toolchain"
      echo; echo "The Python package needs to compile a native C/C++ extension, but a compiler wasn't found or the build failed."
      echo; echo "$REC:"
      echo "→ pkg install clang make"
      echo "→ then retry the failed pip/npm install"
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
    Traceback|PythonSyntax|InvalidJSON|InvalidYAML|InvalidTOML|MakefileSpace|\
    RustToolchain|MissingCompiler)
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

_diag_run() {
  _diag_header

  if [[ "${1:-}" == "-f" ]]; then
    local file="${2:-}"
    if [[ -z "$file" ]]; then
      print_err "No file specified. Usage: tdoc diagnose -f <logfile>"
      exit 1
    fi
    if [[ ! -f "$file" ]]; then
      print_err "File not found: $file"
      exit 1
    fi

    local fname; fname=$(basename "$file")
    local ext="${fname##*.}"

    echo -e "${BOLD}Diagnosing from file: ${file}${RESET}"
    echo

    case "$ext" in
      md|txt|rst|pdf|html|json|yml|yaml|toml)
        echo -e "${YELLOW}${ICON_WARN} Note: '$fname' looks like a documentation/config file, not an error log.${RESET}"
        echo -e "${GRAY}  tdoc diagnose -f works best with: .log .out .err crash logs, or pasted error output.${RESET}"
        echo -e "${GRAY}  For code issues, use: tdoc repo-scan${RESET}"
        echo
        ;;
    esac

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
