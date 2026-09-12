#!/usr/bin/env bash
# ==============================
# TDOC — diagnose engine golden tests
#
# For every fixtures/<name>.log there must be a fixtures/<name>.expected
# containing the issue id that `tdoc diagnose` should report as the top
# (highest-confidence) match. Run this after touching core/rules.tsv or
# core/diagnose_engine.sh.
#
# Usage: ./tests/diagnose/run_tests.sh
# ==============================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TDOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# shellcheck source=/dev/null
source "$TDOC_ROOT/core/diagnose_engine.sh"

pass=0
fail=0

for log_file in "$FIXTURES_DIR"/*.log; do
  [[ -f "$log_file" ]] || continue
  name="$(basename "$log_file" .log)"
  expected_file="$FIXTURES_DIR/${name}.expected"

  if [[ ! -f "$expected_file" ]]; then
    echo "SKIP  $name (no .expected file)"
    continue
  fi

  expected="$(cat "$expected_file")"
  result="$(diag_classify_block "$(cat "$log_file")")"
  # top match = first line, first tab-separated field
  actual="$(echo "$result" | head -n1 | cut -f1)"

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS  $name -> $actual"
    pass=$((pass + 1))
  else
    echo "FAIL  $name -> expected '$expected', got '${actual:-<no match>}'"
    fail=$((fail + 1))
  fi
done

echo
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
