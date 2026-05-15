#!/usr/bin/env bash
# ============================================================
# TDOC — repo_scan.sh
# ============================================================

set -euo pipefail
: "${TDOC_ROOT:?TDOC_ROOT is not set}"

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

_detect_scan_dir() {
  local cwd="$PWD"
  local markers=(
    ".git" "package.json" "Cargo.toml" "setup.py" "pyproject.toml"
    "requirements.txt" "Makefile" "Dockerfile" "docker-compose.yml"
    "docker-compose.yaml" ".github" "go.mod" "composer.json"
  )
  for m in "${markers[@]}"; do
    if [[ -e "$cwd/$m" ]]; then
      echo "$cwd"
      return
    fi
  done
  echo "$HOME"
}

SCAN_DIR="$(_detect_scan_dir)"
SCAN_IS_PROJECT=false
[[ "$SCAN_DIR" != "$HOME" ]] && SCAN_IS_PROJECT=true

_RS_ERRORS=0
_RS_WARNINGS=0
_RS_FILES_SCANNED=0
_RS_SKIPPED=0

_rs_err()  { _RS_ERRORS=$((_RS_ERRORS+1));   echo -e "  ${RED}✖ $*${RESET}"; }
_rs_warn() { _RS_WARNINGS=$((_RS_WARNINGS+1)); echo -e "  ${YELLOW}⚠ $*${RESET}"; }
_rs_ok()   { echo -e "  ${GREEN}✔ $*${RESET}"; }
_rs_info() { echo -e "  ${DIM}ℹ $*${RESET}"; }

_section() {
  local title="$1"
  local pad="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "\n${CYAN}── %-36s ──${RESET}\n" "$title"
}

_count_files() {
  find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" -o -path "*/__pycache__" \
       -o -path "*/target" -o -path "*/.tox" -o -path "*/venv" \
       -o -path "*/.venv" -o -path "*/dist" -o -path "*/.mypy_cache" \) \
    -prune -o -type f -print 2>/dev/null | wc -l
}

_scan_python() {
  _section "$(t L_RS_PYTHON)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local out
    if out=$(python3 -m py_compile "$f" 2>&1); then
      : # OK
    else
      found=1
      local short="${f#$SCAN_DIR/}"
      _rs_err "${short}"
      while IFS= read -r line; do
        [[ -n "$line" ]] && echo -e "    ${DIM}${line}${RESET}"
      done <<< "$out"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/__pycache__" -o -path "*/venv" \
       -o -path "*/.venv" -o -path "*/node_modules" \) -prune \
    -o -name "*.py" -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_shell() {
  _section "$(t L_RS_SHELL)"
  local found=0
  _do_scan_sh() {
    local f="$1" shell="$2"
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local out
    if out=$($shell -n "$f" 2>&1); then
      :
    else
      found=1
      local short="${f#$SCAN_DIR/}"
      _rs_err "${short}"
      while IFS= read -r line; do
        [[ -n "$line" ]] && echo -e "    ${DIM}${line}${RESET}"
      done <<< "$out"
    fi
  }

  while IFS= read -r -d '' f; do
    local shebang
    shebang=$(head -1 "$f" 2>/dev/null || true)
    case "$shebang" in
      "#!/bin/sh"|"#!/usr/bin/env sh") _do_scan_sh "$f" "sh"   ;;
      *)                               _do_scan_sh "$f" "bash" ;;
    esac
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o \( -name "*.sh" -o -name "*.bash" \) -type f -print0 2>/dev/null)

  while IFS= read -r -d '' f; do
    [[ -x "$f" ]] || continue
    local shebang
    shebang=$(head -1 "$f" 2>/dev/null || true)
    case "$shebang" in
      "#!/bin/bash"|"#!/usr/bin/env bash") _do_scan_sh "$f" "bash" ;;
      "#!/bin/sh"|"#!/usr/bin/env sh")     _do_scan_sh "$f" "sh" ;;
    esac
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o -type f ! -name "*.*" -print0 2>/dev/null)

  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_perl() {
  command -v perl >/dev/null 2>&1 || { _rs_info "$(t L_RS_PERL_SKIP)"; return; }
  _section "$(t L_RS_PERL)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local out
    if out=$(perl -c "$f" 2>&1); then
      :
    else
      found=1
      local short="${f#$SCAN_DIR/}"
      _rs_err "${short}"
      while IFS= read -r line; do
        [[ -n "$line" ]] && [[ "$line" != *" syntax OK" ]] && \
          echo -e "    ${DIM}${line}${RESET}"
      done <<< "$out"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o -name "*.pl" -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_js() {
  command -v node >/dev/null 2>&1 || { _rs_info "$(t L_RS_JS_SKIP)"; return; }
  _section "$(t L_RS_JS)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local out
    # node --check hanya cek syntax
    if out=$(node --check "$f" 2>&1); then
      :
    else
      found=1
      local short="${f#$SCAN_DIR/}"
      _rs_err "${short}"
      while IFS= read -r line; do
        [[ -n "$line" ]] && echo -e "    ${DIM}${line}${RESET}"
      done <<< "$out"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" -o -path "*/dist" \) -prune \
    -o \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) -type f -print0 2>/dev/null)

  if command -v tsc >/dev/null 2>&1; then
    while IFS= read -r -d '' f; do
      _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
      local out
      if out=$(tsc --noEmit --skipLibCheck "$f" 2>&1); then
        :
      else
        found=1
        local short="${f#$SCAN_DIR/}"
        _rs_err "${short} (TypeScript)"
        while IFS= read -r line; do
          [[ -n "$line" ]] && echo -e "    ${DIM}${line}${RESET}"
        done <<< "$out"
      fi
    done < <(find "$SCAN_DIR" \
      \( -path "*/.git" -o -path "*/node_modules" -o -path "*/dist" \) -prune \
      -o -name "*.ts" -type f -print0 2>/dev/null)
  fi

  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_yaml() {
  _section "$(t L_RS_YAML)"
  local found=0

  local _yaml_check_cmd=""
  if python3 -c "import yaml" 2>/dev/null; then
    _yaml_check_cmd="python3"
  fi

  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"

    if [[ -n "$_yaml_check_cmd" ]]; then
      local out
      if out=$(python3 -c "
import yaml, sys
try:
    with open(sys.argv[1]) as fh:
        list(yaml.safe_load_all(fh))
except yaml.YAMLError as e:
    print(str(e))
    sys.exit(1)
" "$f" 2>&1); then
        if [[ "$f" == *".github/workflows"* ]]; then
          _check_gha_workflow "$f"
        fi
      else
        found=1
        _rs_err "${short}"
        while IFS= read -r line; do
          [[ -n "$line" ]] && echo -e "    ${DIM}${line}${RESET}"
        done <<< "$out"
      fi
    else
      if grep -Pn "^\t" "$f" >/dev/null 2>&1; then
        found=1
        _rs_warn "${short}: $(t L_RS_YAML_TAB)"
      fi
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o \( -name "*.yml" -o -name "*.yaml" \) -type f -print0 2>/dev/null)

  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_check_gha_workflow() {
  local f="$1"
  local short="${f#$SCAN_DIR/}"

  if ! grep -q "^on:" "$f" && ! grep -q "^\"on\":" "$f"; then
    _rs_warn "${short}: $(t L_RS_GHA_NO_ON)"
  fi
  if ! grep -q "^jobs:" "$f"; then
    _rs_warn "${short}: $(t L_RS_GHA_NO_JOBS)"
  fi

  if grep -n "set-output" "$f" >/dev/null 2>&1; then
    local lines
    lines=$(grep -n "set-output" "$f" | head -5)
    while IFS= read -r line; do
      _rs_warn "${short}:${line%%:*} — $(t L_RS_GHA_SETOUTPUT)"
    done <<< "$lines"
  fi

  if grep -n "save-state" "$f" >/dev/null 2>&1; then
    _rs_warn "${short}: $(t L_RS_GHA_SAVESTATE)"
  fi

  if grep -n "uses: actions/checkout$" "$f" >/dev/null 2>&1; then
    _rs_warn "${short}: $(t L_RS_GHA_UNPIN)"
  fi
}

_scan_json() {
  _section "$(t L_RS_JSON)"
  local found=0

  local _json_cmd=""
  if command -v python3 >/dev/null 2>&1; then
    _json_cmd="python3"
  elif command -v node >/dev/null 2>&1; then
    _json_cmd="node"
  fi

  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    # Skip blank files
    [[ -s "$f" ]] || continue
    local short="${f#$SCAN_DIR/}"
    local out=""
    if [[ "$_json_cmd" == "python3" ]]; then
      if ! out=$(python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>&1); then
        found=1; _rs_err "${short}"; echo -e "    ${DIM}${out}${RESET}"
      fi
    elif [[ "$_json_cmd" == "node" ]]; then
      if ! out=$(node -e "require(process.argv[1])" "$f" 2>&1); then
        found=1; _rs_err "${short}"; echo -e "    ${DIM}${out}${RESET}"
      fi
    else
      _RS_SKIPPED=$((_RS_SKIPPED+1))
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o -name "*.json" -type f -print0 2>/dev/null)

  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_toml() {
  _section "$(t L_RS_TOML)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local out
    if out=$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        sys.exit(0)
with open(sys.argv[1],'rb') as fh:
    tomllib.load(fh)
" "$f" 2>&1); then
      :
    else
      found=1; _rs_err "${short}"; echo -e "    ${DIM}${out}${RESET}"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o -name "*.toml" -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_dockerfile() {
  _section "$(t L_RS_DOCKER)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local lineno=0
    local has_from=false

    while IFS= read -r line; do
      lineno=$((lineno+1))
      [[ -z "$line" || "$line" == \#* ]] && continue
      local instr="${line%% *}"
      instr="${instr^^}"

      case "$instr" in
        FROM) has_from=true ;;
        MAINTAINER)
          _rs_warn "${short}:${lineno} — $(t L_RS_DOCKER_MAINTAINER)" ;;
        ADD)
          _rs_warn "${short}:${lineno} — $(t L_RS_DOCKER_ADD)" ;;
        RUN)
          if [[ "$line" == *"apt-get install"* && "$line" != *"-y"* ]]; then
            _rs_warn "${short}:${lineno} — $(t L_RS_DOCKER_APT)"
          fi
          if [[ "$line" == *" sudo "* || "$line" == *"sudo "* ]]; then
            _rs_warn "${short}:${lineno} — $(t L_RS_DOCKER_SUDO)"
          fi
          ;;
        EXPOSE)
          local port="${line#EXPOSE }"
          if ! [[ "$port" =~ ^[0-9]+(/tcp|/udp)?$ ]]; then
            _rs_warn "${short}:${lineno} — $(t L_RS_DOCKER_PORT): $port"
          fi
          ;;
        "")
          found=1; _rs_err "${short}:${lineno} — $(t L_RS_DOCKER_INSTR): $line" ;;
      esac
    done < "$f"

    if [[ "$has_from" == false ]]; then
      found=1; _rs_err "${short} — $(t L_RS_DOCKER_NO_FROM)"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o \( -name "Dockerfile" -o -name "Dockerfile.*" -o -name "*.dockerfile" \) \
    -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_requirements() {
  _section "$(t L_RS_REQS)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local lineno=0
    while IFS= read -r line; do
      lineno=$((lineno+1))
      [[ -z "$line" || "$line" == \#* ]] && continue
      if [[ "$line" != *"=="* && "$line" != *">="* && "$line" != *"<="* && \
            "$line" != *"~="* && "$line" != \-* ]]; then
        _rs_warn "${short}:${lineno} — $(t L_RS_REQS_NOPIN): ${line}"
      fi
      if echo "$line" | grep -qP '[^\w\[\]<>=!~.,;: @#\-\/\+\*\(\)]' 2>/dev/null; then
        _rs_err "${short}:${lineno} — $(t L_RS_REQS_BADCHAR): ${line}"
        found=1
      fi
    done < "$f"
  done < <(find "$SCAN_DIR" \
    -name "requirements*.txt" -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_env() {
  _section "$(t L_RS_ENV)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local lineno=0
    while IFS= read -r line; do
      lineno=$((lineno+1))
      [[ -z "$line" || "$line" == \#* ]] && continue
      if ! echo "$line" | grep -qP '^[A-Za-z_][A-Za-z0-9_]*\s*=' 2>/dev/null; then
        if ! echo "$line" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*\s*='; then
          _rs_err "${short}:${lineno} — $(t L_RS_ENV_BADLINE): ${line}"
          found=1
        fi
      fi
      local key="${line%%=*}"
      local val="${line#*=}"
      if echo "$key" | grep -qiE "(SECRET|PASSWORD|TOKEN|API_KEY|PRIVATE)" && \
         [[ -n "$val" && "$val" != '""' && "$val" != "''" && \
            "$val" != "your_*" && "$val" != "<*>" ]]; then
        _rs_warn "${short}:${lineno} — $(t L_RS_ENV_SECRET): ${key}"
      fi
    done < "$f"
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" \) -prune \
    -o \( -name ".env" -o -name ".env.*" \) -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_rust() {
  [[ -f "$SCAN_DIR/Cargo.toml" ]] || return
  _section "$(t L_RS_RUST)"
  if command -v cargo >/dev/null 2>&1; then
    local out
    if out=$(cd "$SCAN_DIR" && cargo check 2>&1); then
      _rs_ok "$(t L_RS_NO_ISSUES)"
    else
      _RS_ERRORS=$((_RS_ERRORS+1))
      while IFS= read -r line; do
        [[ -n "$line" ]] && echo -e "  ${DIM}${line}${RESET}"
      done <<< "$out"
    fi
  else
    _rs_info "$(t L_RS_RUST_SKIP)"
  fi
}

_scan_makefile() {
  _section "$(t L_RS_MAKEFILE)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local lineno=0
    local prev_target=""
    while IFS= read -r line; do
      lineno=$((lineno+1))
      if [[ "$line" =~ ^\  && ! "$line" =~ ^# ]]; then
        if [[ -n "$prev_target" ]]; then
          _rs_err "${short}:${lineno} — $(t L_RS_MAKE_TAB): $prev_target"
          found=1
        fi
      fi
      if [[ "$line" =~ ^[A-Za-z_][^:]*: ]]; then
        prev_target="${line%%:*}"
      else
        prev_target=""
      fi
    done < "$f"
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o \( -name "Makefile" -o -name "makefile" -o -name "GNUmakefile" \) \
    -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_markdown() {
  _section "$(t L_RS_MARKDOWN)"
  local found=0
  while IFS= read -r -d '' f; do
    _RS_FILES_SCANNED=$((_RS_FILES_SCANNED+1))
    local short="${f#$SCAN_DIR/}"
    local fm_count
    fm_count=$(grep -c '^---$' "$f" 2>/dev/null || true)
    if [[ $fm_count -eq 1 ]]; then
      _rs_warn "${short}: $(t L_RS_MD_FRONTMATTER)"
    fi
    if grep -qP '!\[.*\]\(\s*\)' "$f" 2>/dev/null; then
      _rs_warn "${short}: $(t L_RS_MD_EMPTY_IMG)"
    fi
    if grep -qP '\[.*\]\(\s*\)' "$f" 2>/dev/null; then
      _rs_warn "${short}: $(t L_RS_MD_EMPTY_LINK)"
    fi
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" \) -prune \
    -o -name "*.md" -type f -print0 2>/dev/null)
  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

_scan_tracebacks() {
  _section "$(t L_RS_TRACEBACK)"
  local found=0
  local patterns=(
    "Traceback (most recent call last)"
    "SyntaxError:"
    "NameError:"
    "TypeError:"
    "AttributeError:"
    "ImportError:"
    "ModuleNotFoundError:"
    "FileNotFoundError:"
    "PermissionError:"
    "RuntimeError:"
    "Exception:"
    "FATAL ERROR"
    "panic:"
    "thread.*panicked"
    "SIGSEGV"
    "Segmentation fault"
    "Error: Cannot find module"
    "npm ERR!"
    "FAILED with exit code"
    "command not found"
  )

  while IFS= read -r -d '' f; do
    local short="${f#$SCAN_DIR/}"
    for pat in "${patterns[@]}"; do
      if grep -qF "$pat" "$f" 2>/dev/null; then
        found=1
        local hits
        hits=$(grep -nF "$pat" "$f" 2>/dev/null | head -3)
        _rs_warn "${short} — $(t L_RS_TB_FOUND): \"${pat}\""
        while IFS= read -r hit; do
          [[ -n "$hit" ]] && echo -e "    ${DIM}${hit}${RESET}"
        done <<< "$hits"
        break
      fi
    done
  done < <(find "$SCAN_DIR" \
    \( -path "*/.git" -o -path "*/node_modules" -o -path "*/__pycache__" \) -prune \
    -o \( -name "*.log" -o -name "*.out" -o -name "*.err" -o -name "output.txt" \) \
    -type f -print0 2>/dev/null)

  [[ $found -eq 0 ]] && _rs_ok "$(t L_RS_NO_ISSUES)"
}

BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${CYAN}${BORDER}${RESET}"
if [[ "$SCAN_IS_PROJECT" == true ]]; then
  echo -e "${CYAN}$(t L_RS_HEADER_PROJECT):\n${BOLD}${SCAN_DIR}${RESET}"
else
  echo -e "${CYAN}$(t L_RS_HEADER_HOME)${RESET}"
fi
echo -e "${CYAN}${BORDER}${RESET}"
echo

_scan_shell
_scan_python
_scan_perl
_scan_js
_scan_yaml
_scan_json
_scan_toml
_scan_dockerfile
_scan_requirements
_scan_makefile
_scan_markdown
_scan_tracebacks

[[ -f "$SCAN_DIR/Cargo.toml" ]] && _scan_rust

echo
echo -e "${CYAN}${BORDER}${RESET}"
echo -e "${CYAN}📊 $(t L_RS_SUMMARY)${RESET}"
echo -e "${CYAN}${BORDER}${RESET}"
echo -e "  ${DIM}$(t L_RS_SCANNED) : ${_RS_FILES_SCANNED}${RESET}"
echo -e "  ${RED}$(t L_BROKEN_COUNT) (error) : ${_RS_ERRORS}${RESET}"
echo -e "  ${YELLOW}$(t L_RS_WARNINGS) : ${_RS_WARNINGS}${RESET}"
[[ $_RS_SKIPPED -gt 0 ]] && \
  echo -e "  ${GRAY}$(t L_RS_SKIPPED_LABEL) : ${_RS_SKIPPED}${RESET}"
echo -e "${CYAN}${BORDER}${RESET}"
echo

if [[ $_RS_ERRORS -gt 0 ]]; then
  echo -e "${RED}✖ $(t L_RS_DONE_ERRORS)${RESET}"
elif [[ $_RS_WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}⚠ $(t L_RS_DONE_WARNINGS)${RESET}"
else
  echo -e "${GREEN}✔ $(t L_RS_DONE_CLEAN)${RESET}"
fi
echo
