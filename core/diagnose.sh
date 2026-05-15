#!/usr/bin/env bash
# ============================================================
# TDOC — diagnose.sh
# ============================================================

set -o nounset
set -o pipefail

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/ai_explain.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
_DIAG_AI_AVAILABLE=false

_diag_check_ai() {
  command -v curl >/dev/null 2>&1 || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  curl -sf --max-time 3 "https://api.anthropic.com" -o /dev/null 2>/dev/null && return 0
  return 1
}

_diag_header() {
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🩺 $(t L_DIAG_HEADER)${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

_diag_read_input() {
  echo -e "${BOLD}$(t L_DIAG_PASTE_PROMPT)${RESET}"
  echo -e "${DIM}$(t L_DIAG_PASTE_MULTILINE_HINT)${RESET}"
  echo

  local lines=()
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && break
    lines+=("$line")
  done

  printf '%s\n' "${lines[@]}"
}

_diag_match_static() {
  local input_lower="$1"

  echo "$input_lower" | grep -qE \
    "dpkg was interrupted|you must manually run.*dpkg|run.*dpkg.*--configure|sub-process.*dpkg.*returned error" \
    && echo "DpkgHalfInstalled" && return

  echo "$input_lower" | grep -qE \
    "unable to lock|could not get lock|lock.*var/lib/dpkg|lock.*apt/lists|another process.*using|waiting for lock" \
    && echo "DpkgLock" && return

  echo "$input_lower" | grep -qE \
    "reinst-required|reinstallation required|must be reinstalled" \
    && echo "DpkgReinstRequired" && return

  echo "$input_lower" | grep -qE \
    "files list.*missing|dpkg.*info.*list" \
    && echo "DpkgMissingFilesList" && return

  echo "$input_lower" | grep -qE \
    "dpkg.*status.*corrupt|status.*database.*corrupt|cannot open.*dpkg/status" \
    && echo "DpkgStatusDB" && return

  echo "$input_lower" | grep -qE \
    "unmet dependencies|dependency problems|broken packages|apt-get install -f" \
    && echo "DpkgBrokenDeps" && return

  echo "$input_lower" | grep -qE \
    "trying to overwrite|conflicts with.*package|file.*owned by" \
    && echo "DpkgFileConflicts" && return

  echo "$input_lower" | grep -qE \
    "no module named|modulenotfounderror|importerror|python.*command not found|python3.*not found|pip.*not found" \
    && echo "Python" && return

  echo "$input_lower" | grep -qE \
    "cannot find module|node.*command not found|npm.*not found|error.*require" \
    && echo "NodeJS" && return

  echo "$input_lower" | grep -qE \
    "git.*command not found|not a git repo|fatal.*not a git" \
    && echo "Git" && return

  echo "$input_lower" | grep -qE \
    "permission denied.*storage|termux-setup-storage|/storage/shared.*no such" \
    && echo "Storage" && return

  echo "$input_lower" | grep -qE \
    "failed to fetch|could not resolve.*mirror|404.*not found.*repo|no release file|gpg error|sources.list" \
    && echo "Repository" && return

  echo "Unknown"
}

_diag_ai_analyze() {
  local error_text="$1"
  local lang_code="${TDOC_LANG:-en}"

  local lang_instruction="Respond in English."
  [[ "$lang_code" == "id" ]] && lang_instruction="Jawab dalam Bahasa Indonesia."

  local system_prompt="You are TDOC, an expert Termux/Linux/shell environment diagnostic assistant. ${lang_instruction}

Analyze the error message or warning text provided by the user. Your response must follow this EXACT format:

🔍 DIAGNOSIS
[One sentence: what this error means]

- ROOT CAUSE
[2-3 bullet points explaining why this happens]

- HOW TO FIX
[Numbered step-by-step fix commands, use code blocks with triple backticks for commands]

- PREVENTION
[1-2 tips to avoid this in the future]

Rules:
- Be concise and practical
- Always include actual commands to run
- If multiple errors are present, address the most critical one first then others
- If the error is from TDOC repo-scan output (like 'Empty image reference' or 'Unclosed frontmatter'), explain what it means in context
- Never say you cannot help"

  local payload
  payload=$(python3 -c "
import json, sys
system = sys.argv[1]
error  = sys.argv[2]
obj = {
  'model': 'claude-sonnet-4-20250514',
  'max_tokens': 1024,
  'system': system,
  'messages': [{'role': 'user', 'content': 'Diagnose this error:\n\n' + error}]
}
print(json.dumps(obj))
" "$system_prompt" "$error_text" 2>/dev/null)

  [[ -z "$payload" ]] && return 1

  local response
  response=$(curl -sf \
    --max-time 30 \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "Content-Type: application/json" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" 2>/dev/null)

  [[ -z "$response" ]] && return 1

  python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['content'][0]['text'])
except:
    sys.exit(1)
" <<< "$response"
}

_diag_offer_fix() {
  local issue="$1"
  case "$issue" in
    DpkgLock|DpkgHalfInstalled|DpkgReinstRequired|DpkgBrokenDeps|\
    DpkgMissingFilesList|DpkgFileConflicts|DpkgStatusDB|\
    Python|NodeJS|Git|Storage)
      echo
      read -rp "  $(t L_DIAG_OFFER_FIX) [y/n]: " ans
      if [[ "$ans" =~ ^[YyTt]$ ]]; then
        mkdir -p "$(dirname "$STATE_FILE")"
        local tmp
        tmp=$(grep -v "^${issue}=" "$STATE_FILE" 2>/dev/null || true)
        echo "$tmp" > "$STATE_FILE"
        echo "${issue}=BROKEN" >> "$STATE_FILE"
        echo
        source "$TDOC_ROOT/core/fix.sh"
      else
        echo
        echo -e "  ${DIM}$(t L_DIAG_FIX_SKIPPED)${RESET}"
        echo -e "  ${DIM}$(t L_DIAG_FIX_HINT): tdoc fix${RESET}"
      fi
      ;;
  esac
}

_diag_run() {
  _diag_header

  local raw_input=""

  if [[ "${1:-}" == "-f" && -n "${2:-}" ]]; then
    local logfile="$2"
    if [[ ! -f "$logfile" ]]; then
      echo -e "${RED}✖ $(t L_DIAG_FILE_NOT_FOUND): $logfile${RESET}"
      exit 1
    fi
    raw_input=$(cat "$logfile")
    echo -e "${DIM}$(t L_DIAG_READ_FROM): ${logfile}${RESET}"
    echo

  elif [[ $# -gt 0 ]]; then
    echo -e "${YELLOW}⚠ $(t L_DIAG_NO_ARGS)${RESET}"
    echo -e "${DIM}$(t L_DIAG_NO_ARGS_HINT)${RESET}"
    echo
    raw_input=$(_diag_read_input)

  else
    raw_input=$(_diag_read_input)
  fi

  echo

  if [[ -z "${raw_input// /}" ]]; then
    echo -e "${RED}✖ $(t L_DIAG_EMPTY_INPUT)${RESET}"
    exit 1
  fi

  echo -e "${BOLD}$(t L_DIAG_INPUT_LABEL):${RESET}"
  echo "$raw_input" | head -5 | sed 's/^/  /' | while IFS= read -r l; do
    echo -e "${DIM}${l}${RESET}"
  done
  local total_lines
  total_lines=$(echo "$raw_input" | wc -l)
  [[ $total_lines -gt 5 ]] && \
    echo -e "  ${DIM}... (+$((total_lines - 5)) $(t L_DIAG_MORE_LINES))${RESET}"
  echo

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo

  if _diag_check_ai; then
    _DIAG_AI_AVAILABLE=true
    spinner_start "$(t L_DIAG_AI_ANALYZING)..."

    local ai_result
    if ai_result=$(_diag_ai_analyze "$raw_input" 2>/dev/null); then
      spinner_stop
      echo -e "${GREEN}✔ $(t L_DIAG_AI_RESULT)${RESET}"
      echo

      while IFS= read -r line; do
        case "$line" in
          "🔍 DIAGNOSIS"*)  echo -e "${CYAN}${BOLD}${line}${RESET}" ;;
          "ROOT CAUSE"*) echo -e "${YELLOW}${BOLD}${line}${RESET}" ;;
          "HOW TO FIX"*) echo -e "${GREEN}${BOLD}${line}${RESET}" ;;
          "PREVENTION"*) echo -e "${BLUE}${BOLD}${line}${RESET}" ;;
          '```'*)           echo -e "${DIM}${line}${RESET}" ;;
          *)                echo "  $line" ;;
        esac
      done <<< "$ai_result"

    else
      spinner_stop
      echo -e "${YELLOW}⚠ $(t L_DIAG_AI_FAILED) — $(t L_DIAG_FALLBACK)${RESET}"
      echo
      _DIAG_AI_AVAILABLE=false
    fi
  fi

  if [[ "$_DIAG_AI_AVAILABLE" == false ]]; then
    spinner_start "$(t L_DIAG_ANALYZING)..."
    sleep 0.3
    local input_lower
    input_lower=$(echo "$raw_input" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    local issue
    issue=$(_diag_match_static "$input_lower")
    spinner_stop

    if [[ "$issue" == "Unknown" ]]; then
      echo -e "${YELLOW}⚠ $(t L_DIAG_NO_MATCH)${RESET}"
      echo
      echo -e "  ${DIM}$(t L_DIAG_NO_MATCH_HINT1)${RESET}"
      echo -e "  ${DIM}$(t L_DIAG_NO_MATCH_HINT2): tdoc scan${RESET}"
      echo -e "  ${DIM}$(t L_DIAG_NO_MATCH_HINT3): https://github.com/djunekz/tdoc/issues${RESET}"
    else
      echo -e "${GREEN}✔ $(t L_DIAG_MATCHED): ${BOLD}${issue}${RESET}"
      echo
      ai_explain "$issue"
      _diag_offer_fix "$issue"
    fi
  fi

  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

_diag_run "$@"
