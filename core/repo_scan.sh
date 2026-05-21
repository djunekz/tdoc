#!/usr/bin/env bash
# ==============================
# TDOC — repo-scan
# Scans a local folder/repository for:
#   - Shell/Python/JS/YAML/JSON/TOML syntax errors
#   - Unreferenced functions (defined but never called)
#   - Unreferenced modules/files (exist but never sourced)
#   - Undefined function calls (called but never defined)
#   - Unpinned dependencies
#   - Broken markdown links
#   - Traceback / error log artifacts
#
# Usage:
#   tdoc repo-scan [path]    (default: current directory)
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

TARGET="${1:-$PWD}"
[[ ! -d "$TARGET" ]] && { print_err "$(t L_REPO_SCAN_NOT_DIR): $TARGET"; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REPO_SCAN_STATE="${HOME}/.tdoc/repo_scan_last.txt"
mkdir -p "$(dirname "$REPO_SCAN_STATE")"
: > "$REPO_SCAN_STATE"

_total_files=0; _broken=0; _warnings=0

echo -e "${CYAN}${BORDER}${RESET}"
echo -e "${CYAN}🔬 $(t L_REPO_SCAN_HEADER):${RESET}"
echo -e "${CYAN}  ${TARGET}${RESET}"
echo -e "${CYAN}${BORDER}${RESET}"
echo

_section() { echo -e "${GRAY}── $1 ──${RESET}"; }
_ok()      { echo -e "  ${GREEN}${ICON_OK} $(t L_REPO_SCAN_NO_ISSUES)${RESET}"; }

_issue() {
  local severity="$1" msg="$2"
  echo "$msg" >> "$REPO_SCAN_STATE"
  case "$severity" in
    error) echo -e "  ${RED}${ICON_ERR} ${msg}${RESET}";    _broken=$((_broken+1)) ;;
    warn)  echo -e "  ${YELLOW}${ICON_WARN} ${msg}${RESET}"; _warnings=$((_warnings+1)) ;;
  esac
}

_section "$(t L_REPO_SCAN_SHELL) (.sh .bash)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  result=$(bash -n "$f" 2>&1) || { _issue "error" "$f: $result"; _found=true; continue; }
  if command -v shellcheck >/dev/null 2>&1; then
    sc=$(shellcheck --severity=error \
      --exclude=SC2155,SC1090,SC1091,SC2034 --shell=bash "$f" 2>&1) || {
      echo "$sc" | grep "^In " | while IFS= read -r line; do
        _issue "error" "$line"; _found=true
      done
    }
  fi
done < <(find "$TARGET" -type f \( -name "*.sh" -o -name "*.bash" \) \
  ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_PYTHON) (.py)"
_found=false
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
if [[ -n "$PY" ]]; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    result=$("$PY" -m py_compile "$f" 2>&1) || { _issue "error" "$f: $result"; _found=true; }
  done < <(find "$TARGET" -type f -name "*.py" \
    ! -path "*/.git/*" ! -path "*/__pycache__/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_JS) (.js .mjs)"
_found=false
if command -v node >/dev/null 2>&1; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    result=$(node --check "$f" 2>&1) || { _issue "error" "$f: $result"; _found=true; }
  done < <(find "$TARGET" -type f \( -name "*.js" -o -name "*.mjs" \) \
    ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_YAML) (.yml .yaml)"
_found=false
if [[ -n "${PY:-}" ]]; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    result=$("$PY" -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2>&1) || {
      _issue "error" "$f: $result"; _found=true
    }
  done < <(find "$TARGET" -type f \( -name "*.yml" -o -name "*.yaml" \) \
    ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_JSON) (.json)"
_found=false
if [[ -n "${PY:-}" ]]; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    "$PY" -m json.tool "$f" >/dev/null 2>&1 || { _issue "error" "$f: invalid JSON"; _found=true; }
  done < <(find "$TARGET" -type f -name "*.json" \
    ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_TOML) (.toml)"
_found=false
if [[ -n "${PY:-}" ]]; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    "$PY" -c "
import sys
try:
    import tomllib; tomllib.load(open(sys.argv[1],'rb'))
except ImportError:
    try:
        import tomli; tomli.load(open(sys.argv[1],'rb'))
    except ImportError:
        pass
" "$f" 2>&1 || { _issue "error" "$f: invalid TOML"; _found=true; }
  done < <(find "$TARGET" -type f -name "*.toml" ! -path "*/.git/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_DOCKER)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  grep -qE "^FROM " "$f" 2>/dev/null || { _issue "warn" "$f: $(t L_REPO_SCAN_DOCKER_NO_FROM)"; _found=true; }
done < <(find "$TARGET" -name "Dockerfile*" ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_REQUIREMENTS)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno+1))
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    echo "$line" | grep -qE "(==|===|~=|!=|>=|<=|>|<|@)" || {
      _issue "warn" "$f:$lineno — $(t L_REPO_SCAN_UNPINNED): $line"; _found=true
    }
  done < "$f"
done < <(find "$TARGET" -name "requirements*.txt" ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_PACKAGEJSON)"
_found=false
if [[ -n "${PY:-}" ]]; then
  while IFS= read -r f; do
    _total_files=$((_total_files+1))
    while IFS= read -r line; do
      [[ -n "$line" ]] && { _issue "warn" "$line"; _found=true; }
    done < <("$PY" - "$f" 2>/dev/null << 'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for sec in ('dependencies','devDependencies'):
        for pkg, ver in data.get(sec, {}).items():
            if ver in ('*','latest') or ver.startswith('^') or ver.startswith('~'):
                print(f"{sys.argv[1]}: unpinned {sec}: {pkg}@{ver}")
except Exception:
    pass
PYEOF
)
  done < <(find "$TARGET" -name "package.json" \
    ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)
fi
$_found || _ok

_section "$(t L_REPO_SCAN_MAKEFILE)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  grep -Pnm1 "^\t? +[^\t]" "$f" 2>/dev/null | grep -q . && {
    _issue "warn" "$f: $(t L_REPO_SCAN_MAKEFILE_SPACES)"; _found=true
  }
done < <(find "$TARGET" -name "Makefile" ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_MARKDOWN) (.md)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  dir=$(dirname "$f")
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    [[ "$link" =~ ^https?:// || "$link" =~ ^# || "$link" =~ ^mailto: ]] && continue
    linkpath="${link%%#*}"
    [[ -z "$linkpath" ]] && continue
    [[ -e "$dir/$linkpath" ]] || {
      _issue "warn" "$f: $(t L_REPO_SCAN_MD_BROKEN_LINK): $link"; _found=true
    }
  done < <(grep -oP '\]\(\K[^)]+(?=\))' "$f" 2>/dev/null)
done < <(find "$TARGET" -name "*.md" ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_LOGS) (.log .out .err)"
_found=false
while IFS= read -r f; do
  _total_files=$((_total_files+1))
  count=$(grep -ciE "Traceback|Error:|Exception:|FATAL|CRITICAL|Segmentation fault" "$f" 2>/dev/null || echo 0)
  [[ "$count" -gt 0 ]] && { _issue "warn" "$f: $count $(t L_REPO_SCAN_LOG_HITS)"; _found=true; }
done < <(find "$TARGET" -type f \( -name "*.log" -o -name "*.out" -o -name "*.err" \) \
  ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_UNREF_FUNCS)"
_found=false

declare -A _def_funcs=()
while IFS= read -r f; do
  while IFS= read -r line; do
    fname=$(echo "$line" | grep -oP '^(function\s+)?\K\w+(?=\s*\(\s*\)\s*\{?)')
    [[ -n "$fname" ]] && _def_funcs["$fname"]="$f"
  done < <(grep -P '^(function\s+)?\w+\s*\(\s*\)\s*\{?' "$f" 2>/dev/null)
done < <(find "$TARGET" -type f \( -name "*.sh" -o -name "*.bash" \) \
  ! -path "*/.git/*" 2>/dev/null)

for fname in "${!_def_funcs[@]}"; do
  src="$(_def_funcs[$fname])"
  calls=$(grep -r --include="*.sh" --include="*.bash" --include="tdoc" \
    -l "\\b${fname}\\b" "$TARGET" 2>/dev/null | grep -cv "^${src}$" || echo 0)
  if [[ "$calls" -eq 0 ]]; then
    if echo "$fname" | grep -qE "^(check_|fix_|auto_fix_|preview_)"; then
      _issue "warn" "$(t L_REPO_SCAN_UNREF_FUNC_MODULE): ${fname}() — $(basename "$src")"
    else
      _issue "warn" "$(t L_REPO_SCAN_UNREF_FUNC): ${fname}() — $(basename "$src")"
    fi
    _found=true
  fi
done
unset _def_funcs
$_found || _ok

_section "$(t L_REPO_SCAN_UNREF_MODULES)"
_found=false
while IFS= read -r f; do
  fname=$(basename "$f")
  fnoext="${fname%.sh}"
  refs=$(grep -r --include="*.sh" --include="*.bash" --include="tdoc" \
    -lE "source[[:space:]]+.*${fname}|\\..*/${fname}|source.*${fnoext}" \
    "$TARGET" 2>/dev/null | wc -l)
  [[ "$refs" -eq 0 ]] && { _issue "warn" "$(t L_REPO_SCAN_UNREF_MODULE): $fname"; _found=true; }
done < <(find "$TARGET" -type f -name "*.sh" ! -path "*/.git/*" 2>/dev/null)
$_found || _ok

_section "$(t L_REPO_SCAN_UNDEF_CALLS)"
_found=false

declare -A _all_defs=()
while IFS= read -r f; do
  while IFS= read -r line; do
    fname=$(echo "$line" | grep -oP '^(function\s+)?\K\w+(?=\s*\(\s*\)\s*\{?)')
    [[ -n "$fname" ]] && _all_defs["$fname"]=1
  done < <(grep -P '^(function\s+)?\w+\s*\(\s*\)\s*\{?' "$f" 2>/dev/null)
done < <(find "$TARGET" -type f \( -name "*.sh" -o -name "*.bash" \) \
  ! -path "*/.git/*" 2>/dev/null)

while IFS= read -r f; do
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno+1))
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    called=$(echo "$line" | grep -oP \
      '(?:^|;\s*)(check_|fix_|auto_fix_|preview_)\w+' \
      | grep -oP '(check_|fix_|auto_fix_|preview_)\w+' | head -1)
    [[ -z "$called" ]] && continue
    [[ -z "${_all_defs[$called]:-}" ]] && {
      _issue "error" "$f:$lineno — $(t L_REPO_SCAN_UNDEF_CALL): ${called}()"
      _found=true
    }
  done < "$f"
done < <(find "$TARGET" -type f \( -name "*.sh" -o -name "*.bash" \) \
  ! -path "*/.git/*" 2>/dev/null)
unset _all_defs
$_found || _ok

echo
echo -e "${CYAN}${BORDER}${RESET}"
echo -e "${CYAN}📊 $(t L_REPO_SCAN_SUMMARY)${RESET}"
echo -e "${CYAN}${BORDER}${RESET}"
echo -e "  $(t L_REPO_SCAN_FILES)  : ${_total_files}"
echo -e "  ${RED}$(t L_BROKEN_COUNT) (error) : ${_broken}${RESET}"
echo -e "  ${YELLOW}$(t L_REPO_SCAN_WARNINGS) : ${_warnings}${RESET}"
echo -e "${CYAN}${BORDER}${RESET}"
echo

if [[ $_broken -gt 0 ]]; then
  echo -e "${RED}${ICON_ERR} $(t L_REPO_SCAN_HAS_ERRORS)${RESET}"
  echo -e "${GRAY}  $(t L_REPO_SCAN_DIAGNOSE_HINT): tdoc diagnose${RESET}"
elif [[ $_warnings -gt 0 ]]; then
  echo -e "${YELLOW}${ICON_WARN} $(t L_REPO_SCAN_HAS_WARNINGS)${RESET}"
  echo -e "${GRAY}  $(t L_REPO_SCAN_DIAGNOSE_HINT): tdoc diagnose${RESET}"
else
  echo -e "${GREEN}${ICON_OK} $(t L_REPO_SCAN_ALL_OK)${RESET}"
fi
echo
