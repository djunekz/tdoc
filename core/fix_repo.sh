#!/usr/bin/env bash
# ==============================
# TDOC — fix_repo.sh
# Fix handlers for all repo-scan issues.
# Sourced by fix.sh, fix_auto.sh, fix_preview.sh
# when repo-fix / repo-fix --auto is called.
# ==============================

: "${TDOC_ROOT:?TDOC_ROOT is not set}"
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/i18n.sh"
load_lang

REPO_FIX_STATE="${HOME}/.tdoc/repo_fix_state.env"
REPO_SCAN_ROOT_FILE="${HOME}/.tdoc/repo_scan_root.txt"
_RF_RE_DQ='^("([^"\\$`]|\\.)*")[[:space:]]*(#.*)?$'

_rf_parse() {
  IFS='=' read -r RF_KEY rest <<< "$1"
  IFS=':' read -r _ RF_FILE RF_LINE <<< "$rest"
}

_rf_confirm() {
  read -rp "$1 $(t L_PROMPT_YN): " ans
  [[ "$ans" =~ ^[YyTt]$ ]]
}

_rf_safe_file() {
  local file="$1" root dir real_dir
  [[ -n "$file" && -f "$file" && ! -L "$file" ]] || return 1
  [[ -r "$REPO_SCAN_ROOT_FILE" ]] || return 1
  IFS= read -r root < "$REPO_SCAN_ROOT_FILE" || return 1
  root=$(cd "$root" 2>/dev/null && pwd -P) || return 1
  dir=$(dirname -- "$file")
  real_dir=$(cd "$dir" 2>/dev/null && pwd -P) || return 1
  [[ "$real_dir" == "$root" || "$real_dir" == "$root"/* ]]
}

_rf_unsafe() {
  print_warn "$(t L_REPO_FIX_UNSAFE_PATH): $1"
  return 1
}

_rf_backup() {
  local file="$1"
  [[ -L "${file}.bak" ]] && rm -f -- "${file}.bak"
  cp -- "$file" "${file}.bak"
}

_rf_lang_value() {
  local line
  line=$(grep -m1 -- "^$2=" "$1") || return 1
  line="${line#*=}"
  [[ "$line" =~ $_RF_RE_DQ ]] || return 1
  printf '%s' "${BASH_REMATCH[1]}"
}

_rf_stub_block() {
  local ref="$1" keys="$2" key val n=0
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    if val=$(_rf_lang_value "$ref" "$key"); then
      echo "${key}=${val}  # [TRANSLATE]"
      n=$((n+1))
    else
      print_warn "$(t L_REPO_FIX_LANG_UNSAFE_VALUE): $key" >&2
    fi
  done <<< "$keys"
  [[ $n -gt 0 ]]
}

fix_repo_ShellSyntax() {
  local file="$1"
  [[ -z "$file" || ! -f "$file" ]] && { print_warn "$(t L_REPO_FIX_FILE_MISSING): $file"; return 1; }
  print_info "$(t L_REPO_FIX_SHELL_HINT): $file"
  print_info "→ bash -n $file"
  bash -n "$file" 2>&1 | head -5
  print_info "$(t L_REPO_FIX_SHELL_MANUAL)"
  return 1
}

auto_fix_repo_ShellSyntax() { fix_repo_ShellSyntax "$1"; }

fix_repo_PythonSyntax() {
  local file="$1"
  [[ -z "$file" || ! -f "$file" ]] && { print_warn "$(t L_REPO_FIX_FILE_MISSING): $file"; return 1; }
  local PY; PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  [[ -z "$PY" ]] && { print_warn "$(t L_REPO_FIX_NO_PYTHON)"; return 1; }
  print_info "$(t L_REPO_FIX_PY_HINT):"
  "$PY" -m py_compile "$file" 2>&1 | head -5
  print_info "$(t L_REPO_FIX_MANUAL_EDIT): $file"
  return 1
}

auto_fix_repo_PythonSyntax() { fix_repo_PythonSyntax "$1"; }

fix_repo_InvalidJSON() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local PY; PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  [[ -z "$PY" ]] && return 1
  print_info "$(t L_REPO_FIX_JSON_DETAIL):"
  "$PY" -m json.tool "$file" 2>&1 | head -5
  if _rf_confirm "$(t L_REPO_FIX_JSON_REFORMAT)"; then
    _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
    local tmp; tmp=$(mktemp)
    if "$PY" -m json.tool "$file" > "$tmp" 2>/dev/null; then
      cp "$tmp" "$file"
      rm -f "$tmp"
      print_ok "$(t L_REPO_FIX_JSON_REFORMATTED): $file"
      return 0
    else
      rm -f "$tmp"
      print_warn "$(t L_REPO_FIX_JSON_MANUAL)"
      return 1
    fi
  fi
  return 1
}

auto_fix_repo_InvalidJSON() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local PY; PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  local tmp; tmp=$(mktemp)
  if "$PY" -m json.tool "$file" > "$tmp" 2>/dev/null; then
    cp "$tmp" "$file"; rm -f "$tmp"
    print_ok "$(t L_REPO_FIX_JSON_REFORMATTED): $file"; return 0
  fi
  rm -f "$tmp"; print_warn "$(t L_REPO_FIX_JSON_MANUAL)"; return 1
}

fix_repo_UnpinnedDep() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local PY; PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  print_info "$(t L_REPO_FIX_UNPINNED_INFO): $file"
  if [[ "$file" == *requirements* && -n "$PY" ]]; then
    if _rf_confirm "$(t L_REPO_FIX_UNPINNED_FREEZE)"; then
      _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
      [[ -L "${file}.pinned" ]] && rm -f -- "${file}.pinned"
      spinner_start "pip freeze..."
      if "$PY" -m pip freeze > "${file}.pinned" 2>/dev/null; then
        spinner_stop
        print_ok "$(t L_REPO_FIX_UNPINNED_FROZEN): ${file}.pinned"
        print_info "$(t L_REPO_FIX_UNPINNED_REVIEW): mv ${file}.pinned $file"
      else
        spinner_stop; print_warn "$(t L_REPO_FIX_UNPINNED_FAIL)"
      fi
    fi
  else
    print_info "$(t L_REPO_FIX_UNPINNED_MANUAL)"
  fi
}

auto_fix_repo_UnpinnedDep() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local PY; PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  [[ "$file" != *requirements* || -z "$PY" ]] && {
    print_warn "$(t L_REPO_FIX_UNPINNED_MANUAL)"; return 1
  }
  [[ -L "${file}.pinned" ]] && rm -f -- "${file}.pinned"
  spinner_start "pip freeze..."
  if "$PY" -m pip freeze > "${file}.pinned" 2>/dev/null; then
    spinner_stop; print_ok "$(t L_REPO_FIX_UNPINNED_FROZEN): ${file}.pinned"
  else
    spinner_stop; print_warn "$(t L_REPO_FIX_UNPINNED_FAIL)"
  fi
}

fix_repo_LangKeyMissing() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local target_dir; target_dir=$(dirname "$file")
  local ref="$target_dir/en.sh"
  _rf_safe_file "$ref" || { print_warn "$(t L_REPO_FIX_LANG_NO_REF)"; return 1; }

  print_info "$(t L_REPO_FIX_LANG_MISSING_INFO): $(basename "$file")"
  local REF_KEYS LF_KEYS
  REF_KEYS=$(grep -oP '^L_\w+' "$ref" | sort)
  LF_KEYS=$(grep -oP '^L_\w+' "$file" | sort)
  local missing_keys
  missing_keys=$(comm -23 <(echo "$REF_KEYS") <(echo "$LF_KEYS"))

  if [[ -z "$missing_keys" ]]; then
    print_ok "$(t L_REPO_FIX_LANG_INSYNC)"; return 0
  fi

  echo "$missing_keys" | while IFS= read -r key; do
    print_info "  missing: $key"
  done

  if _rf_confirm "$(t L_REPO_FIX_LANG_STUB)"; then
    local block
    block=$(_rf_stub_block "$ref" "$missing_keys") || return 1
    _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
    echo >> "$file"
    echo "# ── Auto-added stubs by tdoc repo-fix — translate these ──" >> "$file"
    printf '%s\n' "$block" >> "$file"
    print_ok "$(t L_REPO_FIX_LANG_STUBBED): $(basename "$file")"
    print_warn "$(t L_REPO_FIX_LANG_TRANSLATE_HINT)"
  fi
}

auto_fix_repo_LangKeyMissing() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local ref; ref="$(dirname "$file")/en.sh"
  _rf_safe_file "$ref" || return 1
  local REF_KEYS LF_KEYS missing_keys block
  REF_KEYS=$(grep -oP '^L_\w+' "$ref" | sort)
  LF_KEYS=$(grep -oP '^L_\w+' "$file" | sort)
  missing_keys=$(comm -23 <(echo "$REF_KEYS") <(echo "$LF_KEYS"))
  [[ -z "$missing_keys" ]] && return 0
  block=$(_rf_stub_block "$ref" "$missing_keys") || return 1
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  echo >> "$file"
  echo "# ── Auto-added stubs by tdoc repo-fix ──" >> "$file"
  printf '%s\n' "$block" >> "$file"
  print_ok "$(t L_REPO_FIX_LANG_STUBBED): $(basename "$file")"
}

fix_repo_LangKeyOrphan() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local ref; ref="$(dirname "$file")/en.sh"
  _rf_safe_file "$ref" || return 1
  local REF_KEYS LF_KEYS orphans
  REF_KEYS=$(grep -oP '^L_\w+' "$ref" | sort)
  LF_KEYS=$(grep -oP '^L_\w+' "$file" | sort)
  orphans=$(comm -13 <(echo "$REF_KEYS") <(echo "$LF_KEYS"))
  [[ -z "$orphans" ]] && { print_ok "$(t L_REPO_FIX_LANG_INSYNC)"; return 0; }
  echo "$orphans" | while IFS= read -r key; do print_info "  orphan: $key"; done
  if _rf_confirm "$(t L_REPO_FIX_LANG_REMOVE_ORPHANS)"; then
    _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      sed -i "/^${key}=/d" "$file" 2>/dev/null || true
    done <<< "$orphans"
    print_ok "$(t L_REPO_FIX_LANG_ORPHANS_REMOVED): $(basename "$file")"
  fi
}

auto_fix_repo_LangKeyOrphan() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  local ref; ref="$(dirname "$file")/en.sh"
  _rf_safe_file "$ref" || return 1
  local orphans
  orphans=$(comm -13 \
    <(grep -oP '^L_\w+' "$ref" | sort) \
    <(grep -oP '^L_\w+' "$file" | sort))
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    sed -i "/^${key}=/d" "$file" 2>/dev/null || true
  done <<< "$orphans"
  print_ok "$(t L_REPO_FIX_LANG_ORPHANS_REMOVED): $(basename "$file")"
}

fix_repo_MakefileSpace() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  print_info "$(t L_REPO_FIX_MAKEFILE_INFO): $file"
  if _rf_confirm "$(t L_REPO_FIX_MAKEFILE_CONVERT)"; then
    _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
    _rf_backup "$file" || return 1
    sed -i 's/^    /\t/g' "$file"
    print_ok "$(t L_REPO_FIX_MAKEFILE_FIXED) ($(t L_REPO_FIX_BACKUP): ${file}.bak)"
    return 0
  fi
  return 1
}

auto_fix_repo_MakefileSpace() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  _rf_backup "$file" || return 1
  sed -i 's/^    /\t/g' "$file"
  print_ok "$(t L_REPO_FIX_MAKEFILE_FIXED): $file"
}

fix_repo_MissingSourceGuard() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  print_info "$(t L_REPO_FIX_GUARD_INFO): $file"
  print_info "$(t L_REPO_FIX_GUARD_HINT)"
  print_info "  : \"\${TDOC_ROOT:?TDOC_ROOT is not set}\""
  if _rf_confirm "$(t L_REPO_FIX_GUARD_INSERT)"; then
    _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
    _rf_backup "$file" || return 1
    sed -i '1{/^#!\/usr\/bin\/env bash/a \\n: "${TDOC_ROOT:?TDOC_ROOT is not set}"}' "$file"
    print_ok "$(t L_REPO_FIX_GUARD_INSERTED): $file"
    return 0
  fi
  return 1
}
auto_fix_repo_MissingSourceGuard() {
  local file="$1"
  _rf_safe_file "$file" || { _rf_unsafe "$file"; return 1; }
  _rf_backup "$file" || return 1
  sed -i '1{/^#!\/usr\/bin\/env bash/a \\n: "${TDOC_ROOT:?TDOC_ROOT is not set}"}' "$file"
  print_ok "$(t L_REPO_FIX_GUARD_INSERTED): $file"
}

fix_repo_BrokenMdLink() {
  local file="$1"; [[ -z "$file" || ! -f "$file" ]] && return 1
  print_info "$(t L_REPO_FIX_MD_LINK_INFO): $file"
  print_info "$(t L_REPO_FIX_MD_LINK_MANUAL)"
  return 1
}

auto_fix_repo_BrokenMdLink() { fix_repo_BrokenMdLink "$1"; }

fix_repo_UnrefFunc()      { print_info "$(t L_REPO_FIX_UNREF_HINT): $1"; return 1; }
fix_repo_UnrefFuncModule(){ print_info "$(t L_REPO_FIX_UNREF_MODULE_HINT): $1"; return 1; }
fix_repo_UnrefModule()    { print_info "$(t L_REPO_FIX_UNREF_FILE_HINT): $1"; return 1; }
fix_repo_UndefCall()      { print_info "$(t L_REPO_FIX_UNDEF_HINT): $1"; return 1; }
fix_repo_ShellCheck()     { fix_repo_ShellSyntax "$1"; }
fix_repo_JSSyntax()       { print_info "$(t L_REPO_FIX_JS_HINT): $1"; return 1; }
fix_repo_YAMLSyntax()     { print_info "$(t L_REPO_FIX_YAML_HINT): $1"; return 1; }
fix_repo_InvalidTOML()    { print_info "$(t L_REPO_FIX_TOML_HINT): $1"; return 1; }
fix_repo_Traceback()      { print_info "$(t L_REPO_FIX_TRACEBACK_HINT): $1"; return 1; }
fix_repo_DockerNoFrom()   { print_info "$(t L_REPO_FIX_DOCKER_HINT): $1"; return 1; }
fix_repo_MissingTKey()    { print_info "$(t L_REPO_FIX_TKEY_HINT): $1"; return 1; }

auto_fix_repo_UnrefFunc()      { fix_repo_UnrefFunc "$1"; }
auto_fix_repo_UnrefFuncModule(){ fix_repo_UnrefFuncModule "$1"; }
auto_fix_repo_UnrefModule()    { fix_repo_UnrefModule "$1"; }
auto_fix_repo_UndefCall()      { fix_repo_UndefCall "$1"; }
auto_fix_repo_ShellCheck()     { fix_repo_ShellCheck "$1"; }
auto_fix_repo_JSSyntax()       { fix_repo_JSSyntax "$1"; }
auto_fix_repo_YAMLSyntax()     { fix_repo_YAMLSyntax "$1"; }
auto_fix_repo_InvalidTOML()    { fix_repo_InvalidTOML "$1"; }
auto_fix_repo_Traceback()      { fix_repo_Traceback "$1"; }
auto_fix_repo_DockerNoFrom()   { fix_repo_DockerNoFrom "$1"; }
auto_fix_repo_MissingTKey()    { fix_repo_MissingTKey "$1"; }
