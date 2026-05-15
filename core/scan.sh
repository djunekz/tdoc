#!/usr/bin/env bash
# TDOC — System Scan

set -euo pipefail
: "${TDOC_ROOT:?TDOC_ROOT is not set}"

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
mkdir -p "$(dirname "$STATE_FILE")"
: > "$STATE_FILE"

BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "🧪 $(t L_SCAN_HEADER)"
echo

check_item() {
  local key="$1" label="$2" cmd="$3"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "$key=OK" >> "$STATE_FILE"
    print_ok "$label"
  else
    echo "$key=BROKEN" >> "$STATE_FILE"
    print_err "$label"
  fi
}

source "$TDOC_ROOT/core/repo_security.sh"
if scan_repo_security; then
  echo "Repository=OK" >> "$STATE_FILE"; print_ok "$(t L_SCAN_REPO)"
else
  echo "Repository=BROKEN" >> "$STATE_FILE"; print_err "$(t L_SCAN_REPO)"
fi

if [[ -d "$HOME/storage/shared" && -w "$HOME/storage/shared" ]]; then
  echo "Storage=OK" >> "$STATE_FILE"; print_ok "$(t L_SCAN_STORAGE)"
elif [[ -d "$HOME/storage" ]]; then
  echo "Storage=PARTIAL" >> "$STATE_FILE"; print_warn "$(t L_SCAN_STORAGE_PARTIAL)"
else
  echo "Storage=BROKEN" >> "$STATE_FILE"; print_err "$(t L_SCAN_STORAGE)"
fi

check_item "Python"       "$(t L_SCAN_PYTHON)"  "python -c 'print(1)'"
check_item "NodeJS"       "$(t L_SCAN_NODEJS)"  "node -e 'process.exit(0)'"
check_item "Git"          "$(t L_SCAN_GIT)"     "git --version"
check_item "TermuxVersion" "$(t L_SCAN_TERMUX)" "[[ -n \"\$PREFIX\" && -d \"\$PREFIX/bin\" ]]"

if [[ -d "$TDOC_ROOT/modules" ]]; then
  for mod in "$TDOC_ROOT/modules"/*.sh; do
    [[ -f "$mod" ]] || continue
    mod_name=$(basename "$mod" .sh)
    case "$mod_name" in node|python|storage|repo) continue ;; esac
    source "$mod"
    declare -f "check_${mod_name}" >/dev/null 2>&1 && "check_${mod_name}"
  done
fi

ok=0; broken=0; partial=0
while IFS='=' read -r _ value; do
  case "$value" in OK) ok=$((ok+1));; PARTIAL) partial=$((partial+1));; *) broken=$((broken+1));; esac
done < "$STATE_FILE"

echo
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${CYAN}📝 $(t L_SCAN_SUMMARY)${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo -e "${GREEN}$(t L_OK_COUNT)      : $ok${RESET}"
[[ $partial -gt 0 ]] && echo -e "${YELLOW}$(t L_PARTIAL_COUNT) : $partial${RESET}"
echo -e "${RED}$(t L_BROKEN_COUNT)  : $broken${RESET}"
echo -e "${CYAN}$BORDER${RESET}"
echo
echo -e "✔ $(t L_SCAN_DONE) — $(t L_SCAN_HINT)"

_tdoc_is_project_dir() {
  local markers=(".git" "package.json" "Cargo.toml" "setup.py" "pyproject.toml"
    "requirements.txt" "Makefile" "Dockerfile" "docker-compose.yml"
    "docker-compose.yaml" ".github" "go.mod" "composer.json")
  for m in "${markers[@]}"; do
    [[ -e "$PWD/$m" ]] && return 0
  done
  return 1
}

if _tdoc_is_project_dir; then
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}📁 $(t L_RS_HEADER_PROJECT): ${BOLD}${PWD}${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  source "$TDOC_ROOT/core/repo_scan.sh"
fi
