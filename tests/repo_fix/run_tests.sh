#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TDOC_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
CASE=""

new_case() {
  CASE="$WORK/$1"
  rm -rf "$CASE"
  mkdir -p "$CASE/prefix/lib" "$CASE/home/.tdoc" "$CASE/repo/lang" "$CASE/victim"
  ln -s "$TDOC_SRC" "$CASE/prefix/lib/tdoc"
  printf 'L_A="x"\n' > "$CASE/victim/target.sh"
  cp "$CASE/victim/target.sh" "$CASE/victim/target.sh.orig"
  printf 'L_A="a"\n' > "$CASE/repo/lang/en.sh"
  printf 'L_A="x"\n' > "$CASE/repo/lang/id.sh"
}

run_tdoc() {
  (cd "$CASE/home" && env HOME="$CASE/home" PREFIX="$CASE/prefix" LANG=C timeout 180 \
    bash "$CASE/prefix/lib/tdoc/tdoc" "$@" </dev/null >"$CASE/out.txt" 2>&1)
  return 0
}

scan_and_fix() {
  run_tdoc repo-scan "$CASE/repo"
  run_tdoc repo-fix --auto
}

victim_unchanged() {
  cmp -s "$CASE/victim/target.sh" "$CASE/victim/target.sh.orig"
}

report() {
  if [[ "$2" == "ok" ]]; then
    echo "PASS  $1"
    pass=$((pass + 1))
  else
    echo "FAIL  $1"
    fail=$((fail + 1))
  fi
}

new_case symlinked_lang_file
printf 'L_A="a"\nL_PWN=$(touch %s/marker)\n' "$CASE" > "$CASE/repo/lang/en.sh"
rm -f "$CASE/repo/lang/id.sh"
ln -s "$CASE/victim/target.sh" "$CASE/repo/lang/id.sh"
scan_and_fix
if victim_unchanged && [[ ! -e "$CASE/marker" ]]; then report "symlinked lang file is never written through" ok; else report "symlinked lang file is never written through" bad; fi
if ! grep -q "id.sh" "$CASE/home/.tdoc/repo_fix_state.env" 2>/dev/null; then report "symlinked lang file is not scanned" ok; else report "symlinked lang file is not scanned" bad; fi

new_case tampered_state_symlink
printf 'L_A="a"\nL_PWN=$(touch %s/marker)\n' "$CASE" > "$CASE/repo/lang/en.sh"
rm -f "$CASE/repo/lang/id.sh"
ln -s "$CASE/victim/target.sh" "$CASE/repo/lang/id.sh"
printf '%s\n' "$CASE/repo" > "$CASE/home/.tdoc/repo_scan_root.txt"
printf 'LangKeyMissing=BROKEN:%s:\nLangKeyOrphan=BROKEN:%s:\n' "$CASE/repo/lang/id.sh" "$CASE/repo/lang/id.sh" > "$CASE/home/.tdoc/repo_fix_state.env"
run_tdoc repo-fix --auto
if victim_unchanged && [[ ! -e "$CASE/marker" ]]; then report "fix handlers reject a symlink even with a tampered state file" ok; else report "fix handlers reject a symlink even with a tampered state file" bad; fi

new_case path_outside_scanned_root
mkdir -p "$CASE/outside/lang"
printf 'L_A="a"\nL_B="b"\n' > "$CASE/outside/lang/en.sh"
printf 'L_A="x"\n' > "$CASE/outside/lang/id.sh"
cp "$CASE/outside/lang/id.sh" "$CASE/outside/id.sh.orig"
printf '%s\n' "$CASE/repo" > "$CASE/home/.tdoc/repo_scan_root.txt"
printf 'LangKeyMissing=BROKEN:%s:\n' "$CASE/outside/lang/id.sh" > "$CASE/home/.tdoc/repo_fix_state.env"
run_tdoc repo-fix --auto
if cmp -s "$CASE/outside/lang/id.sh" "$CASE/outside/id.sh.orig"; then report "fix handlers reject a file outside the scanned repository" ok; else report "fix handlers reject a file outside the scanned repository" bad; fi

new_case missing_scan_root
printf 'L_A="a"\nL_B="b"\n' > "$CASE/repo/lang/en.sh"
cp "$CASE/repo/lang/id.sh" "$CASE/id.sh.orig"
printf 'LangKeyMissing=BROKEN:%s:\n' "$CASE/repo/lang/id.sh" > "$CASE/home/.tdoc/repo_fix_state.env"
run_tdoc repo-fix --auto
if cmp -s "$CASE/repo/lang/id.sh" "$CASE/id.sh.orig"; then report "fix handlers refuse to write without a recorded scan root" ok; else report "fix handlers refuse to write without a recorded scan root" bad; fi

new_case adversarial_stub_values
{
  printf 'L_A="a"\n'
  printf 'L_OK="fine value"\n'
  printf 'L_ESC="cost \\$5 and \\"quoted\\""\n'
  printf 'L_CMD=$(touch %s/marker)\n' "$CASE"
  printf 'L_CMD2="a"$(touch %s/marker)\n' "$CASE"
  printf 'L_TICK="`touch %s/marker`"\n' "$CASE"
  printf 'L_VAR="$(touch %s/marker)"\n' "$CASE"
  printf 'L_SEMI="a"; touch %s/marker\n' "$CASE"
} > "$CASE/repo/lang/en.sh"
scan_and_fix
if grep -q '^L_OK="fine value"  # \[TRANSLATE\]$' "$CASE/repo/lang/id.sh" && grep -q '^L_ESC=' "$CASE/repo/lang/id.sh"; then report "safe values are still stubbed" ok; else report "safe values are still stubbed" bad; fi
if ! grep -qE 'L_CMD|L_TICK|L_VAR|L_SEMI' "$CASE/repo/lang/id.sh"; then report "unsafe values are not propagated" ok; else report "unsafe values are not propagated" bad; fi
( source "$CASE/repo/lang/id.sh" ) >/dev/null 2>&1
if [[ ! -e "$CASE/marker" ]]; then report "sourcing the fixed lang file executes nothing" ok; else report "sourcing the fixed lang file executes nothing" bad; fi

new_case makefile_backup_symlink
printf 'all:\n    echo hi\n' > "$CASE/repo/Makefile"
ln -s "$CASE/victim/target.sh" "$CASE/repo/Makefile.bak"
printf '%s\n' "$CASE/repo" > "$CASE/home/.tdoc/repo_scan_root.txt"
printf 'MakefileSpace=BROKEN:%s:\n' "$CASE/repo/Makefile" > "$CASE/home/.tdoc/repo_fix_state.env"
run_tdoc repo-fix --auto
if victim_unchanged; then report "Makefile backup does not write through a symlink" ok; else report "Makefile backup does not write through a symlink" bad; fi
if [[ -f "$CASE/repo/Makefile.bak" && ! -L "$CASE/repo/Makefile.bak" ]]; then report "Makefile backup is created as a regular file" ok; else report "Makefile backup is created as a regular file" bad; fi

new_case pinned_symlink
printf 'requests\n' > "$CASE/repo/requirements.txt"
ln -s "$CASE/victim/target.sh" "$CASE/repo/requirements.txt.pinned"
printf '%s\n' "$CASE/repo" > "$CASE/home/.tdoc/repo_scan_root.txt"
printf 'UnpinnedDep=BROKEN:%s:\n' "$CASE/repo/requirements.txt" > "$CASE/home/.tdoc/repo_fix_state.env"
run_tdoc repo-fix --auto
if victim_unchanged; then report "pinned output does not write through a symlink" ok; else report "pinned output does not write through a symlink" bad; fi

new_case legitimate_stub
printf 'L_A="a"\nL_B="beta"\n' > "$CASE/repo/lang/en.sh"
scan_and_fix
if grep -q '^L_B="beta"  # \[TRANSLATE\]$' "$CASE/repo/lang/id.sh"; then report "legitimate missing key is stubbed" ok; else report "legitimate missing key is stubbed" bad; fi

echo
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
