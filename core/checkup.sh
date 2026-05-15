#!/usr/bin/env bash
# ==============================
# TDOC — checkup
# Full shareable health report.
#
# Usage:
#   tdoc checkup           → print to terminal
#   tdoc checkup --save    → save to ~/.tdoc/checkup_<timestamp>.txt
#   tdoc checkup --json    → output as JSON
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
source "$TDOC_ROOT/core/version.sh"
load_lang

STATE_FILE="${PREFIX}/var/lib/tdoc/state.env"
CHECKUP_DIR="${HOME}/.tdoc"
mkdir -p "$CHECKUP_DIR"

MODE="${1:-}"

_cu_cmd() {
  eval "$1" 2>/dev/null || echo "$(t L_CHECKUP_UNAVAILABLE)"
}

_cu_json_esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

_cu_collect() {
  CU_TDOC_VERSION="${TDOC_VERSION:-unknown}"
  CU_TDOC_CODENAME="${TDOC_CODENAME:-unknown}"
  CU_GENERATED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
  CU_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

  CU_ANDROID_VER="$(_cu_cmd "getprop ro.build.version.release")"
  CU_ANDROID_SDK="$(_cu_cmd "getprop ro.build.version.sdk")"
  CU_DEVICE_MODEL="$(_cu_cmd "getprop ro.product.model")"
  CU_DEVICE_BRAND="$(_cu_cmd "getprop ro.product.brand")"
  CU_CPU_ABI="$(_cu_cmd "getprop ro.product.cpu.abi")"

  CU_TERMUX_VER="$(_cu_cmd "dpkg-query -W -f='\${Version}' termux-tools")"
  CU_SHELL="${SHELL:-unknown}"
  CU_ARCH="$(_cu_cmd "uname -m")"
  CU_KERNEL="$(_cu_cmd "uname -r")"
  CU_PKG_COUNT="$(_cu_cmd "dpkg --get-selections 2>/dev/null | wc -l")"

  CU_STORAGE_PREFIX="$(_cu_cmd "df -h '$PREFIX' | tail -1 | awk '{print \$2\" total / \"\$4\" free\"}'")"
  CU_STORAGE_HOME="$(_cu_cmd "df -h '$HOME' | tail -1 | awk '{print \$2\" total / \"\$4\" free\"}'")"
  if [[ -d "$HOME/storage/shared" && -w "$HOME/storage/shared" ]]; then
    CU_STORAGE_SHARED="accessible"
  elif [[ -d "$HOME/storage" ]]; then
    CU_STORAGE_SHARED="partial"
  else
    CU_STORAGE_SHARED="not setup"
  fi

  if [[ -f /proc/meminfo ]]; then
    CU_RAM_TOTAL="$(_cu_cmd "awk '/MemTotal/{printf \"%d MB\", \$2/1024}' /proc/meminfo")"
    CU_RAM_AVAIL="$(_cu_cmd "awk '/MemAvailable/{printf \"%d MB\", \$2/1024}' /proc/meminfo")"
  else
    CU_RAM_TOTAL="$(t L_CHECKUP_UNAVAILABLE)"
    CU_RAM_AVAIL="$(t L_CHECKUP_UNAVAILABLE)"
  fi

  CU_CPU_CORES="$(_cu_cmd "nproc")"
  CU_CPU_MODEL="$(_cu_cmd "grep -m1 'Hardware\|model name' /proc/cpuinfo | cut -d: -f2 | xargs")"

  CU_PYTHON_VER="$(_cu_cmd "python --version")"
  CU_NODE_VER="$(_cu_cmd "node --version")"
  CU_GIT_VER="$(_cu_cmd "git --version")"
  CU_BASH_VER="$(_cu_cmd "bash --version | head -1")"

  CU_SOURCES="$(_cu_cmd "grep -v '^#' '$PREFIX/etc/apt/sources.list' | grep -v '^$'")"

  CU_DPKG_AUDIT="$(dpkg --audit 2>/dev/null | head -5 || true)"

  CU_SCAN_OK=0
  CU_SCAN_BROKEN=0
  CU_SCAN_PARTIAL=0
  CU_SCAN_ITEMS=""
  if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" ]] && continue
      CU_SCAN_ITEMS+="    $k: $v\n"
      case "$v" in
        OK)      CU_SCAN_OK=$((CU_SCAN_OK+1)) ;;
        PARTIAL) CU_SCAN_PARTIAL=$((CU_SCAN_PARTIAL+1)) ;;
        *)       CU_SCAN_BROKEN=$((CU_SCAN_BROKEN+1)) ;;
      esac
    done < "$STATE_FILE"
    CU_SCAN_DATE="$(_cu_cmd "stat -c %y '$STATE_FILE' | cut -d. -f1")"
  else
    CU_SCAN_DATE="$(t L_CHECKUP_NO_SCAN)"
    CU_SCAN_ITEMS="    $(t L_CHECKUP_NO_SCAN)\n"
  fi

  # Fix report tail
  if [[ -f "${HOME}/.tdoc/report.json" ]]; then
    CU_FIX_HISTORY="$(tail -c 400 "${HOME}/.tdoc/report.json")"
  else
    CU_FIX_HISTORY="$(t L_CHECKUP_NO_HISTORY)"
  fi
}

_cu_print_text() {
  local B="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo -e "${CYAN}${B}${RESET}"
  echo -e "${CYAN}🩺 $(t L_CHECKUP_HEADER)${RESET}"
  echo -e "${CYAN}${B}${RESET}"
  echo -e "${GRAY}  $(t L_CHECKUP_GENERATED): ${CU_GENERATED_AT}${RESET}"
  echo -e "${GRAY}  tdoc v${CU_TDOC_VERSION} (${CU_TDOC_CODENAME})${RESET}"
  echo

  echo -e "${BOLD}📱 $(t L_CHECKUP_DEVICE)${RESET}"
  echo -e "  ${CU_DEVICE_BRAND} ${CU_DEVICE_MODEL}"
  echo -e "  Android ${CU_ANDROID_VER} (SDK ${CU_ANDROID_SDK})  |  ABI: ${CU_CPU_ABI}"
  echo -e "  Kernel: ${CU_KERNEL}  |  Arch: ${CU_ARCH}"
  echo

  echo -e "${BOLD}🖥  $(t L_CHECKUP_TERMUX)${RESET}"
  echo -e "  termux-tools: ${CU_TERMUX_VER}"
  echo -e "  Shell: ${CU_SHELL}"
  echo -e "  Installed packages: ${CU_PKG_COUNT}"
  echo

  echo -e "${BOLD}⚙  $(t L_CHECKUP_HARDWARE)${RESET}"
  echo -e "  CPU: ${CU_CPU_MODEL} (${CU_CPU_CORES} cores)"
  echo -e "  RAM: ${CU_RAM_TOTAL} total / ${CU_RAM_AVAIL} available"
  echo -e "  Storage (PREFIX): ${CU_STORAGE_PREFIX}"
  echo -e "  Storage (HOME): ${CU_STORAGE_HOME}"
  echo -e "  Shared storage: ${CU_STORAGE_SHARED}"
  echo

  echo -e "${BOLD}🔧 $(t L_CHECKUP_TOOLS)${RESET}"
  echo -e "  Bash:    ${CU_BASH_VER}"
  echo -e "  Python:  ${CU_PYTHON_VER}"
  echo -e "  Node.js: ${CU_NODE_VER}"
  echo -e "  Git:     ${CU_GIT_VER}"
  echo

  echo -e "${BOLD}📦 $(t L_CHECKUP_REPO)${RESET}"
  while IFS= read -r line; do
    echo -e "  ${line}"
  done <<< "$CU_SOURCES"
  echo

  echo -e "${BOLD}🧪 $(t L_CHECKUP_SCAN_STATE)${RESET}"
  echo -e "  $(t L_CHECKUP_LAST_SCAN): ${CU_SCAN_DATE}"
  echo -e "  ${GREEN}$(t L_OK_COUNT): ${CU_SCAN_OK}${RESET}  ${YELLOW}$(t L_PARTIAL_COUNT): ${CU_SCAN_PARTIAL}${RESET}  ${RED}$(t L_BROKEN_COUNT): ${CU_SCAN_BROKEN}${RESET}"
  echo
  echo -e "${CU_SCAN_ITEMS}"

  if [[ -n "$CU_DPKG_AUDIT" ]]; then
    echo -e "${BOLD}🔍 $(t L_CHECKUP_DPKG_AUDIT)${RESET}"
    while IFS= read -r line; do
      echo -e "  ${RED}${line}${RESET}"
    done <<< "$CU_DPKG_AUDIT"
    echo
  fi

  echo -e "${BOLD}📋 $(t L_CHECKUP_FIX_HISTORY)${RESET}"
  echo -e "  ${GRAY}${CU_FIX_HISTORY}${RESET}"
  echo

  echo -e "${CYAN}${B}${RESET}"
  echo -e "${GRAY}  $(t L_CHECKUP_SHARE_HINT)${RESET}"
  echo -e "${CYAN}${B}${RESET}"
  echo
}

_cu_print_json() {
  local scan_json=""
  if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" ]] && continue
      scan_json+="\"$(echo "$k" | tr 'A-Z' 'a-z')\": \"$(_cu_json_esc "$v")\", "
    done < "$STATE_FILE"
    scan_json="${scan_json%, }"
  fi

  cat <<JSON
{
  "tool": "tdoc",
  "version": "$(_cu_json_esc "$CU_TDOC_VERSION")",
  "codename": "$(_cu_json_esc "$CU_TDOC_CODENAME")",
  "generated_at": "$(_cu_json_esc "$CU_GENERATED_AT")",
  "device": {
    "brand": "$(_cu_json_esc "$CU_DEVICE_BRAND")",
    "model": "$(_cu_json_esc "$CU_DEVICE_MODEL")",
    "android_version": "$(_cu_json_esc "$CU_ANDROID_VER")",
    "android_sdk": "$(_cu_json_esc "$CU_ANDROID_SDK")",
    "cpu_abi": "$(_cu_json_esc "$CU_CPU_ABI")",
    "arch": "$(_cu_json_esc "$CU_ARCH")",
    "kernel": "$(_cu_json_esc "$CU_KERNEL")"
  },
  "termux": {
    "version": "$(_cu_json_esc "$CU_TERMUX_VER")",
    "shell": "$(_cu_json_esc "$CU_SHELL")",
    "installed_packages": "$(_cu_json_esc "$CU_PKG_COUNT")"
  },
  "hardware": {
    "cpu_model": "$(_cu_json_esc "$CU_CPU_MODEL")",
    "cpu_cores": "$(_cu_json_esc "$CU_CPU_CORES")",
    "ram_total": "$(_cu_json_esc "$CU_RAM_TOTAL")",
    "ram_available": "$(_cu_json_esc "$CU_RAM_AVAIL")",
    "storage_prefix": "$(_cu_json_esc "$CU_STORAGE_PREFIX")",
    "storage_home": "$(_cu_json_esc "$CU_STORAGE_HOME")",
    "shared_storage": "$(_cu_json_esc "$CU_STORAGE_SHARED")"
  },
  "tools": {
    "bash": "$(_cu_json_esc "$CU_BASH_VER")",
    "python": "$(_cu_json_esc "$CU_PYTHON_VER")",
    "nodejs": "$(_cu_json_esc "$CU_NODE_VER")",
    "git": "$(_cu_json_esc "$CU_GIT_VER")"
  },
  "scan": {
    "last_scan": "$(_cu_json_esc "$CU_SCAN_DATE")",
    "ok": $CU_SCAN_OK,
    "partial": $CU_SCAN_PARTIAL,
    "broken": $CU_SCAN_BROKEN,
    "items": { $scan_json }
  }
}
JSON
}

spinner_start "$(t L_CHECKUP_SCANNING)..."
source "$TDOC_ROOT/core/scan.sh" >/dev/null 2>&1 || true
spinner_stop

_cu_collect

case "$MODE" in
  --json)
    _cu_print_json
    ;;
  --save)
    OUTFILE="${CHECKUP_DIR}/checkup_${CU_TIMESTAMP}.txt"
    _cu_print_text > "$OUTFILE"
    echo
    print_ok "$(t L_CHECKUP_SAVED): $OUTFILE"
    print_info "$(t L_CHECKUP_SHARE_CMD): cat $OUTFILE"
    echo
    ;;
  *)
    _cu_print_text
    print_info "$(t L_CHECKUP_SAVE_HINT): tdoc checkup --save"
    print_info "$(t L_CHECKUP_JSON_HINT): tdoc checkup --json"
    echo
    ;;
esac
