#!/usr/bin/env bash
# TDOC — Benchmark

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

BORDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "⚡ $(t L_BENCH_HEADER)"
echo -e "${GRAY}$(t L_BENCH_INTRO)${RESET}"; echo

echo -e "${CYAN}$BORDER\n💾 $(t L_BENCH_STORAGE)\n$BORDER${RESET}"
TEST_FILE="$HOME/.tdoc/.bench_tmp"; mkdir -p "$HOME/.tdoc"
spinner_start "$(t L_BENCH_MEASURING)"
START_NS=$(date +%s%N 2>/dev/null || date +%s)
dd if=/dev/zero of="$TEST_FILE" bs=1M count=10 conv=fsync 2>/dev/null
END_NS=$(date +%s%N 2>/dev/null || date +%s)
spinner_stop; rm -f "$TEST_FILE"

if [[ "$START_NS" =~ N$ ]]; then
  echo -e "  ${GRAY}$(t L_BENCH_NO_NS)${RESET}"
else
  ELAPSED_MS=$(( (END_NS - START_NS) / 1000000 ))
  if [[ $ELAPSED_MS -gt 0 ]]; then
    SPEED_MB=$(( 10 * 1000 / ELAPSED_MS ))
    echo -e "  ${GREEN}$(t L_BENCH_SPEED): ~${SPEED_MB} MB/s ($(t L_BENCH_TEST))${RESET}"
    [[ $SPEED_MB -lt 5 ]] && print_warn "$(t L_BENCH_SLOW)"
  fi
fi
echo

echo -e "${CYAN}$BORDER\n🌐 $(t L_BENCH_NETWORK)\n$BORDER${RESET}"
declare -A MIRRORS=(
  ["packages.termux.dev (Official)"]="packages.termux.dev"
  ["mirrors.tuna.tsinghua.edu.cn (CN)"]="mirrors.tuna.tsinghua.edu.cn"
  ["mirror.nevacloud.com (ID)"]="mirror.nevacloud.com"
  ["plug-mirror.rcac.purdue.edu (US)"]="plug-mirror.rcac.purdue.edu"
  ["grimler.se (EU)"]="grimler.se"
)
best_host=""; best_ms=99999
for label in "${!MIRRORS[@]}"; do
  host="${MIRRORS[$label]}"
  spinner_start "Ping $label..."
  if result=$(ping -c 2 -W 3 "$host" 2>/dev/null); then
    avg=$(echo "$result" | grep -oE '[0-9]+\.[0-9]+/[0-9]+\.[0-9]+/[0-9]+\.[0-9]+' | cut -d'/' -f2)
    spinner_stop
    if [[ -n "$avg" ]]; then
      avg_int=${avg%%.*}
      if   [[ $avg_int -lt 50  ]]; then echo -e "  ${GREEN}✔${RESET} $label → ${GREEN}${avg}ms${RESET}"
      elif [[ $avg_int -lt 150 ]]; then echo -e "  ${YELLOW}~${RESET} $label → ${YELLOW}${avg}ms${RESET}"
      else                               echo -e "  ${RED}✖${RESET} $label → ${RED}${avg}ms${RESET}"; fi
      [[ $avg_int -lt $best_ms ]] && { best_ms=$avg_int; best_host=$label; }
    fi
  else
    spinner_stop
    echo -e "  ${RED}✖${RESET} $label → $(t L_BENCH_UNREACHABLE)"
  fi
done
echo
[[ -n "$best_host" ]] && { print_ok "$(t L_BENCH_BEST_MIRROR): $best_host (${best_ms}ms)"; print_info "$(t L_BENCH_CHANGE_MIRROR)"; }
echo

echo -e "${CYAN}$BORDER\n💻 $(t L_BENCH_CPU)\n$BORDER${RESET}"
if [[ -f /proc/cpuinfo ]]; then
  cores=$(grep -c 'processor' /proc/cpuinfo 2>/dev/null || echo "?")
  model=$(grep 'Hardware\|model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)
  echo -e "  $(t L_BENCH_CORES): ${GREEN}$cores${RESET}"
  [[ -n "$model" ]] && echo -e "  $(t L_BENCH_MODEL)   : ${GRAY}$model${RESET}"
fi
if [[ -f /proc/meminfo ]]; then
  total=$(awk '/MemTotal/{printf "%.0f MB",$2/1024}' /proc/meminfo)
  avail=$(awk '/MemAvailable/{printf "%.0f MB",$2/1024}' /proc/meminfo)
  echo -e "  $(t L_BENCH_RAM_TOTAL): ${GREEN}$total${RESET}"
  echo -e "  $(t L_BENCH_RAM_AVAIL): ${CYAN}$avail${RESET}"
fi
echo; print_ok "$(t L_BENCH_DONE)"
