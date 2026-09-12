#!/usr/bin/env bash
# ==============================
# TDOC — diagnose engine (pure matching logic)
#
# This file has NO side effects and NO dependency on ui.sh/i18n.sh so it
# can be sourced directly by tests without booting the whole app. All the
# actual classification rules live in data, not in if/elif chains, so:
#   - adding a rule never risks "stealing" a match from a more specific
#     one just because of where it sits in the file
#   - a low-specificity rule (like the generic "error:"/"traceback"
#     catch-all) can never outrank a specific rule, because ranking is by
#     weight, not by source-code order
#   - rules are gated by "context" (what tool produced this log) so a
#     dpkg-specific rule can't fire on pip output and vice versa
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
DIAG_RULES_FILE="${DIAG_RULES_FILE:-$TDOC_ROOT/core/rules.tsv}"

# Below this weight, a match is "generic only" — no specific rule fired,
# just a broad marker like the word "error:". Callers should present
# these with lower confidence instead of a confident checkmark.
DIAG_LOW_CONFIDENCE_WEIGHT=2

# ── Context detection ────────────────────────────────────────────────────────
# Figures out which tool most likely produced this log. Used to gate rules
# so e.g. a dpkg-specific pattern can't match inside pip output just
# because both happen to contain the word "error".
_diag_detect_contexts() {
  local text="$1"
  local -a ctx=()

  echo "$text" | grep -qiE "collecting |downloading .*\.(tar\.gz|whl)|error: subprocess-exited-with-error|building wheel for|getting requirements to build wheel|pip install" \
    && ctx+=("pip")
  echo "$text" | grep -qiE "npm err!|npm warn|npm install" \
    && ctx+=("npm")
  echo "$text" | grep -qiE "dpkg: |setting up |unpacking |sub-process.*dpkg|var/lib/dpkg" \
    && ctx+=("dpkg")
  echo "$text" | grep -qiE "^e: |unable to fetch|failed to fetch|apt-get|apt update|apt install" \
    && ctx+=("apt")
  echo "$text" | grep -qiE "fatal: not a git repository|^remote: |github\.com|git clone|git commit" \
    && ctx+=("git")
  echo "$text" | grep -qiE "traceback \(most recent call last\)|\.py\", line" \
    && ctx+=("python")
  echo "$text" | grep -qiE "node:internal|at object\." \
    && ctx+=("node")

  echo "${ctx[*]:-}"
}

_diag_context_allowed() {
  local rule_context="$1" detected="$2"
  [[ "$rule_context" == "any" ]] && return 0
  [[ -z "$detected" ]] && return 0   # unknown context: don't gate, best effort
  [[ " $detected " == *" $rule_context "* ]] && return 0
  return 1
}

# ── Rule loading ─────────────────────────────────────────────────────────────
# Rules are TAB-separated: id<TAB>context<TAB>ere_pattern<TAB>weight
# (TAB, not "|", because the patterns themselves use "|" for alternation)
_diag_load_rules() {
  [[ -f "$DIAG_RULES_FILE" ]] || { echo "diagnose: rules file not found: $DIAG_RULES_FILE" >&2; return 1; }
  grep -v '^\s*#' "$DIAG_RULES_FILE" | grep -v '^\s*$'
}

# Classify a single line/block of text against all rules given a set of
# already-detected contexts. Prints "id\tweight" for the best match, or
# nothing if no rule matched.
diag_classify_text() {
  local text="$1" detected_contexts="$2"
  local best_id="" best_weight=-1

  while IFS=$'\t' read -r id ctx pattern weight; do
    [[ -z "$id" ]] && continue
    _diag_context_allowed "$ctx" "$detected_contexts" || continue
    echo "$text" | grep -qiE "$pattern" || continue
    if (( weight > best_weight )); then
      best_id="$id"
      best_weight="$weight"
    fi
  done < <(_diag_load_rules)

  [[ -n "$best_id" ]] && printf '%s\t%s\n' "$best_id" "$best_weight"
}

# Classify a whole multi-line block: returns one "id\tweight" per distinct
# issue found across all lines (deduplicated), highest-weight match per
# line, in first-seen order.
#
# Important: if ANY line in the block produced a specific (above-threshold)
# match, generic catch-all matches found on OTHER lines of the same block
# are dropped. A block is one report about one problem — once we have a
# real diagnosis for it, a stray "error:" elsewhere in the same paste is
# noise, not a second issue.
diag_classify_block() {
  local input="$1"
  local detected
  detected=$(_diag_detect_contexts "$(echo "$input" | tr '[:upper:]' '[:lower:]')")

  local -A seen=()
  local -a ids=() weights=()
  local has_specific=false

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local lower
    lower=$(echo "$line" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    local result
    result=$(diag_classify_text "$lower" "$detected")
    [[ -z "$result" ]] && continue
    local id="${result%%$'\t'*}" w="${result##*$'\t'}"
    [[ -n "${seen[$id]:-}" ]] && continue
    seen["$id"]=1
    ids+=("$id")
    weights+=("$w")
    (( w > DIAG_LOW_CONFIDENCE_WEIGHT )) && has_specific=true
  done <<< "$input"

  local i
  for i in "${!ids[@]}"; do
    if $has_specific && (( weights[i] <= DIAG_LOW_CONFIDENCE_WEIGHT )); then
      continue
    fi
    printf '%s\t%s\n' "${ids[$i]}" "${weights[$i]}"
  done
}
