# TDOC — Changelog

All notable changes to TDOC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.2.4] — 2026-06-16

### Added
- **`lang/fr.sh`** — New language: French

### Fixed
- **`core/explain.sh`** — Fix unbound variable STATE_FILE

---

## [2.2.2] — 2026-05-27

### Added
- **`core/repo_fix.sh`** — Entrypoint for `tdoc repo-fix`, `tdoc repo-fix --auto`, `tdoc repo-fix --preview`. Reads structured state from `~/.tdoc/repo_fix_state.env` written by `repo-scan` and dispatches to per-issue fix handlers.
- **`core/fix_repo.sh`** — Fix handler library for all repo-scan issue types. Each issue has three handlers: `fix_repo_<KEY>` (interactive), `auto_fix_repo_<KEY>` (non-interactive), and preview string in `repo_fix.sh`. Fixable automatically: `InvalidJSON` (reformat), `UnpinnedDep` (pip freeze), `LangKeyMissing` (stub from en.sh), `LangKeyOrphan` (remove), `MakefileSpace` (sed tabs), `MissingSourceGuard` (insert guard). Manual-only: `ShellSyntax`, `PythonSyntax`, `UndefCall`, `BrokenMdLink`, `UnrefFunc`, `UnrefModule`.
- **`core/repo_scan.sh` v2** — Extended with 4 new audit sections beyond syntax checking: (7) language file key sync (`lang/en.sh` vs all other lang files — missing keys and orphan keys); (8) `t()` call audit (every `t L_KEY` call in every `.sh` file cross-checked against `lang/en.sh` — flags undefined keys with file and line number); (9) missing source guards (scripts using `$TDOC_ROOT` or `$PREFIX` without `: "${VAR:?}"` guard); structured state output — each issue now written to `~/.tdoc/repo_fix_state.env` as `KEY=BROKEN:filepath:lineno` for consumption by `repo_fix.sh`.
- **`tdoc repo-fix`**, **`tdoc repo-fix --preview`**, **`tdoc repo-fix --auto`** — New top-level commands wired in `tdoc` entrypoint.
- **`core/diagnose.sh`** — `-f` flag now detects documentation/config file extensions (`.md`, `.txt`, `.json`, `.yml`, etc.) and warns the user that `diagnose -f` is designed for error logs, not source files — with a redirect hint to `tdoc repo-scan`.
- **`lang/en.sh`** + **`lang/id.sh`** — New keys: `L_REPO_FIX_*` (40 keys), `L_REPO_SCAN_LANG_SYNC`, `L_REPO_SCAN_LANG_MISSING_KEY`, `L_REPO_SCAN_LANG_ORPHAN_KEY`, `L_REPO_SCAN_TKEY_SYNC`, `L_REPO_SCAN_TKEY_MISSING`, `L_REPO_SCAN_SOURCE_GUARD`, `L_REPO_SCAN_NO_GUARD`, `L_REPO_SCAN_FIX_HINT`, `L_REPO_SCAN_AUTOFIX_HINT`.
- **`tdoc` help menu** — Added `repo-fix`, `repo-fix --preview`, `repo-fix --auto` entries. Hardcoded strings used for new command descriptions to avoid `L_KEY` fallback on fresh installs before lang files are updated.

### Fixed
- **`tdoc` help menu — `L_CHECKUP_HEADER` fallback**: Key was added to `checkup.sh` but not to the lang files shipped with the repo. Help menu now uses hardcoded `"Full Checkup Report"` to prevent `L_CHECKUP_HEADER` literal from appearing on fresh installs.
- **`core/diagnose.sh` — `-f` with non-log file**: Previously ran silently and returned "no match" when given a `.md`, `.json`, or similar file — confusing because there was no error, just nothing detected. Now shows a clear warning with file extension, explains what `-f` is for, and redirects to `tdoc repo-scan`.

---

## [2.2.0] — 2026-05-15

### Added
- **`core/repo_scan.sh`** — New multi-language code scanner engine (659 lines). Scans an entire project folder for bugs, syntax errors, deprecated patterns, traceback logs, and common misconfigurations across all major file types:
  - **Python** (`.py`) — `python3 -m py_compile`: detects `SyntaxError`, `IndentationError`
  - **Shell / Bash** (`.sh`, `.bash`, shebang-detected executables) — `bash -n` / `sh -n`
  - **Perl** (`.pl`) — `perl -c` (skipped gracefully if Perl not installed)
  - **JavaScript** (`.js`, `.mjs`, `.cjs`) — `node --check`; TypeScript (`.ts`) via `tsc --noEmit` if available
  - **YAML** (`.yml`, `.yaml`) — `PyYAML` safe-load; extra lint for GitHub Actions workflows (deprecated `set-output`, `save-state`, unpinned `actions/checkout`, missing `on:` / `jobs:`)
  - **JSON** (`.json`) — `json.load` via Python or `require()` via Node
  - **TOML** (`.toml`) — `tomllib` (Python 3.11+) / `tomli` fallback
  - **Dockerfile** — built-in lint: `FROM` missing, `MAINTAINER` deprecated, `ADD` vs `COPY`, `apt-get install` without `-y`, `sudo` inside container, invalid `EXPOSE` port
  - **`requirements.txt`** — unpinned dependencies, suspicious characters
  - **`.env`** — `KEY=VALUE` format validation, potential secrets committed (detects `SECRET`, `TOKEN`, `PASSWORD`, `API_KEY`, `PRIVATE` keys with non-placeholder values)
  - **Makefile** — TAB-vs-spaces enforcement on recipe lines
  - **Markdown** (`.md`) — unclosed YAML frontmatter, empty `![]()` image refs, empty `[]()` hyperlinks
  - **Log files** (`.log`, `.out`, `.err`) — pattern scan for 20+ traceback/error signatures: Python `Traceback`, `SyntaxError`, `NameError`, Rust `panic:`, `SIGSEGV`, `npm ERR!`, `command not found`, etc.
  - **Rust** — `cargo check` invoked if `Cargo.toml` exists at scan root and `cargo` is available
- **`tdoc repo-scan`** — New top-level command wired in the main `tdoc` entrypoint. Scans the current working directory if it looks like a project folder; falls back to `$HOME` otherwise.
- **Auto project detection in `tdoc scan`** — After the standard Termux system scan completes, `scan.sh` now checks whether `$PWD` contains any project marker (`.git`, `Dockerfile`, `package.json`, `Cargo.toml`, `setup.py`, `pyproject.toml`, `requirements.txt`, `Makefile`, `docker-compose.yml`, `.github`, `go.mod`, `composer.json`). If a marker is found, `repo_scan.sh` is automatically sourced and the full code scan runs in the same session — zero extra commands needed.
- **`lang/en.sh`** + **`lang/id.sh`** — 44 new language keys each (`L_RS_*`) covering all `repo_scan.sh` output. Additionally, `L_DIAG_*` keys extended with: `L_DIAG_PASTE_MULTILINE_HINT`, `L_DIAG_MORE_LINES`, `L_DIAG_AI_ANALYZING`, `L_DIAG_AI_RESULT`, `L_DIAG_AI_FAILED`, `L_DIAG_FALLBACK`, `L_DIAG_NO_ARGS`, `L_DIAG_NO_ARGS_HINT`, `L_DIAG_FILE_NOT_FOUND`, `L_DIAG_READ_FROM`. All output fully bilingual EN/ID.
- **`install.sh`** — Updated post-install message to list `tdoc repo-scan`.
- **`man/tdoc.1`** — Man page updated with full `repo-scan` and updated `diagnose` command documentation.

### Changed
- **`core/version.sh`** — Rewritten to read all values from `VERSION` file at `$TDOC_ROOT/VERSION` instead of hardcoding them. Uses `source` on the `KEY=VALUE` file and maps `VERSION` → `TDOC_VERSION`, `CODENAME` → `TDOC_CODENAME`, `BUILD_DATE` → `TDOC_BUILD_DATE`. Includes graceful fallback to `"unknown"` / empty strings if the file is missing. `TDOC_NAME` remains set here as it is not a release artifact.
- **`VERSION`** — Format changed from a bare version number (`2.1.1`) to structured `KEY=VALUE` pairs:
  ```
  VERSION=2.2.0
  CODENAME=Diagnostix
  BUILD_DATE=2026-05-15
  ```
  This file is now the **single source of truth** for all version metadata. Updating a release only requires editing `VERSION` — no changes to `version.sh`, `ui_version.sh`, or any other file needed.
- **`core/ui_version.sh`** — Removed 8 duplicate color variable declarations (`BOLD`, `DIM`, `CYAN`, `GREEN`, `YELLOW`, `RESET`, `BORDER`, `ICON_INFO`) that were redefined locally instead of sourcing `ui.sh`. Now sources `ui.sh` like every other core file, ensuring color consistency if `ui.sh` is ever updated. Border width corrected to 42 characters matching the rest of TDOC. `Codename` and `Build` lines are conditionally shown — only printed when the value is non-empty, so a minimal `VERSION` file with only `VERSION=x.y.z` still renders cleanly.
- **`install.sh`** — Added explicit copy of `VERSION` file to `$INSTALL_DIR/VERSION` via `install -Dm644`. Previously `VERSION` was never copied during installation, causing `version.sh` to fall back to hardcoded values at runtime and `tdoc version` to always show the old version even after an update. Added `tdoc diagnose` and `tdoc diagnose -f <log>` to the post-install commands list.
- **`core/diagnose.sh`** — Fully rewritten. Previous version accepted error text as CLI arguments (`tdoc diagnose <text>`), which caused bash to crash on special characters like `![]()` before the script even started. New behaviour:
  - **Interactive multi-line paste** (default): user runs `tdoc diagnose`, pastes any number of lines freely (traceback, `tdoc repo-scan` output, log snippet, etc.), submits with an empty line.
  - **File mode** (`tdoc diagnose -f <path>`): reads error text directly from a log file.
  - **Argument guard**: if arguments are passed, script rejects them with a friendly explanation and falls through to interactive mode — no more bash crashes.
  - **AI engine**: when internet is available, the full error text is sent to Claude (Anthropic API, `claude-sonnet-4-20250514`) and returns a structured diagnosis: `🔍 DIAGNOSIS`, `📌 ROOT CAUSE`, `🔧 HOW TO FIX`, `💡 PREVENTION` — each with actual commands to run.
  - **Offline fallback**: when AI is unavailable, falls back to the original 40+ static pattern matcher (`_diag_match_static`) with `ai_explain` output and fix offer. No degradation in offline environments.
- **`core/scan.sh`** — Added `_tdoc_is_project_dir()` helper and post-scan hook at the end of the scan flow. No changes to existing scan logic or state file format.
- **`core/repo_scan.sh`** — Shell scanner default changed from `sh -n` to `bash -n` for `.sh` files without an explicit `#!/bin/sh` shebang. Fixes false-positive syntax errors on bash-syntax files (arrays, `[[ ]]`, `local`) that have no shebang. `sh -n` is now only used when shebang is explicitly `#!/bin/sh` or `#!/usr/bin/env sh`. Section separator width fixed to 42 characters, matching the header border.
- **`tdoc` entrypoint** — Help menu updated: `tdoc diagnose [error]` replaced with `tdoc diagnose` and `tdoc diagnose -f <file>` entries reflecting the new interface. `tdoc repo-scan` added to the Diagnosis section.

### Fixed
- **`install.sh` — `VERSION` not copied**: `tdoc version` always showed the old hardcoded version after installation because `VERSION` was never copied to `$INSTALL_DIR`. Fixed by adding `install -Dm644 VERSION "$INSTALL_DIR/VERSION"`.
- **`core/ui_version.sh` — duplicate color declarations**: Colors were redeclared locally instead of using `ui.sh`, causing potential inconsistency. Now sources `ui.sh` directly.
- **`core/repo_scan.sh` — shell scanner false positives**: Files using bash syntax (`[[ ]]`, arrays, `local`) without a shebang were incorrectly checked with `sh -n`, producing `Syntax error: "(" unexpected`. Now defaults to `bash -n`.
- **`core/repo_scan.sh` — section line width**: Section separators were unbounded in length. Now capped at 42 characters with `printf "── %-36s ──"` to match the header border.

---

## [2.1.1] — 2026-05-02

### Added
- **`core/diagnose.sh`**: New `tdoc diagnose` command. Accepts a raw error message as argument or interactively prompts for input. Matches 40+ known error patterns across dpkg, apt, Python, Node.js, Git, storage, and repository issues. After matching, calls `ai_explain` for the identified issue and offers to run a fix immediately.
- **`core/checkup.sh`**: New `tdoc checkup` command. Runs a fresh scan then generates a full shareable health report — device info (brand, model, Android version, ABI), Termux environment, CPU/RAM/storage, installed tool versions, repository sources, scan state, dpkg audit output, and fix history. Supports `--save` (write to `~/.tdoc/checkup_<timestamp>.txt`) and `--json` (machine-readable output).
- **`tdoc watch [interval]`**: Shorthand alias for `tdoc doctor --live [interval]`. Both forms remain supported.
- **`lang/en.sh`** + **`lang/id.sh`**: New language keys for `diagnose` (`L_DIAG_*`) and `checkup` (`L_CHECKUP_*`) commands — fully bilingual EN/ID.
- **`tdoc` help menu**: Updated with `diagnose`, `watch`, `checkup --save`, `checkup --json` entries.

### Fixed
- **`modules/dpkg.sh` — `check_dpkg_lock`**: Previously flagged lock as STALE whether or not a process held it (`locked=true` in both branches). Now correctly: STALE only when file exists **and** no process holds it (`fuser` exits non-zero). Lock held by active dpkg/apt = OK. No lock file = OK.
- **`modules/dpkg.sh` — `check_dpkg_file_conflicts`**: Previous heuristic flagged any package with a `Conflicts:` metadata field as broken — this is normal dpkg metadata present in every package. Now cross-checks each conflict target against the list of actually-installed packages. Only flags BROKEN when both conflicting packages are simultaneously installed.
- **`core/ai_explain.sh`**: Rebuilt from scratch after a `cat >>` append left the `case` block structurally invalid (`*)` was never closed before dpkg cases were added), causing `syntax error near unexpected token '('` on line 71. All cases now in a single well-formed `case`/`esac`.
- **`core/checkup.sh`**: Removed `local` keyword used outside a function in the `CU_WATCH_LOG` block — invalid in bash strict mode. Broken count calculation replaced: was `grep -cv '=OK$'` (counted blank lines), now counted via the same `case` loop used for OK/PARTIAL, matching `scan.sh` behaviour exactly.
- **`ci.yml` — ShellCheck**: Added `SC1090`, `SC1091`, and `SC2034` to `--exclude` list. All were legitimate false positives in a multi-file sourced codebase.
- **`codeql.yml` — Semgrep**: Replaced deprecated Docker image `semgrep/semgrep` with `pip install semgrep`. Replaced unavailable ruleset `p/bash` (HTTP 404) with `r/bash`. Changed `--error` to `--no-error`.

### Changed
- **`core/watch.sh`**: Reverted to original implementation from v2.0.0.
- **`tdoc` entrypoint**: Rebuilt from original v2.0.0 source. New commands (`diagnose`, `watch`, `checkup`) wired following existing patterns.

---

## [2.1.0] — 2026-05-01

### Added
- **modules/dpkg.sh**: New dpkg health scan module. Detects 7 dpkg/apt error classes:
  - Stale lock file (DpkgLock)
  - Missing or corrupt status database (DpkgStatusDB)
  - Half-installed / half-configured packages (DpkgHalfInstalled)
  - reinst-required / ghost packages (DpkgReinstRequired)
  - Broken / unmet dependencies (DpkgBrokenDeps)
  - Packages with missing files list (DpkgMissingFilesList)
  - File conflicts between packages (DpkgFileConflicts)
- **core/fix_dpkg.sh**: Fix handlers for all 7 dpkg issues — manual, auto, and preview modes.
- **lang/en.sh** + **lang/id.sh**: 60+ new language keys for all dpkg scan/fix/explain strings.
- **core/ai_explain.sh**: Static explanations for all 7 dpkg issue types (causes, how-it-works, recommended fix).
- **core/explain.sh**: Wired dpkg keys into the explanation runner.
- **core/fix_preview.sh**: Preview actions for all dpkg fix types.

---

## [2.0.0] — 2026-04-25

### Bug Fixes
- **CRITICAL** `report.sh`: Fixed incorrect array indirection in `_report_write()`. `${!var[@]}` replaced with proper `eval` so the `fixed` field in reports is no longer always empty `[]`.
- **fix_auto.sh**: `auto_fix_Storage()` no longer crashes when the user taps "Deny" on the Android dialog. Added proper error handling compatible with `set -euo pipefail`.
- **scan.sh**: Fixed storage check — previously `[[ -w "$HOME" ]]` was always `true` in Termux. Now correctly checks `$HOME/storage/shared`.
- **fix_preview.sh**: `STATE_FILE` was never set. Now uses the correct path from `$PREFIX`. All statuses (BROKEN, PARTIAL, etc.) are handled, not just a subset.
- **repo_security_json.sh**: Added guard for empty `WARNINGS`/`DANGERS` arrays to prevent crashes under `set -u`.
- **doctor_json.sh**: `escape_json()` now uses `awk` to correctly handle literal newlines (previously `sed 's/\\n/...'` did not match real newlines).

### Removed
- `core/ai_helper.sh` — duplicate of `ai_engine.sh` + `ai_explain.sh` (noted in v1.0.5 changelog but never actually deleted)
- `core/spinner.sh` — duplicate of the spinner engine already present in `core/ui.sh`
- `core/repo.sh` — duplicate of `modules/repo.sh`, never sourced by `scan.sh`
- `ai_engine.sh` is now a shim that forwards to `ai_explain.sh`

### New Features
- **`tdoc check <package>`** — Ad-hoc status check for any arbitrary Termux package (binary, dpkg, apt-cache).
- **`tdoc history`** — Display scan & fix history from `~/.tdoc/report.json` with a formatted table (Python) or raw fallback.
- **`tdoc doctor --live [seconds]`** — Continuous monitoring mode. Re-scans every N seconds and notifies via `termux-notification` on status changes.
- **`tdoc benchmark`** — Measures storage write speed, network latency to Termux mirrors, and CPU/RAM info.
- **`tdoc fix Python`** — Python can now be repaired automatically (`pkg reinstall python`) instead of being silently skipped.
- **`tdoc fix Git`** — Git can now be repaired automatically (`pkg install git`) instead of being silently skipped.
- **i18n (Internationalization)** — TDOC output is automatically in Bahasa Indonesia when `$LANG=id_ID*`. Override with `TDOC_LANG=id tdoc scan`, save permanently with `tdoc lang set id`. Language files live in `lang/id.sh` and `lang/en.sh`.
- **Plugin system** — `scan.sh` now auto-loads and runs `check_<modname>()` from all `.sh` files in the `modules/` folder. Users can add custom checks without touching core files.
- **`tdoc lang set <code>`** — Set and persist the display language to `~/.tdoc/config`.
- **`tdoc lang list`** — List all available languages and show the currently active one.
- **`tdoc --lang <code> <command>`** — One-shot language override per command without saving.

### Improved
- `fix.sh`: Python and Git are now interactive, offering `pkg reinstall`/`pkg install` with user confirmation.
- `scan.sh`: Added `PARTIAL` status to the summary output.
- `report.sh`: JSON writes are now atomic via `mktemp` with empty-array guards.
- `install.sh`: Now also copies the `lang/` directory.
- `modules/storage.sh`: Synced with the corrected storage check in `scan.sh`.
- `ai_explain.sh`: All explanations are now fully internationalized via `t()` — no hardcoded strings.
- All core scripts now use `t()` for every user-facing string; zero hardcoded output text remains.

---

## [1.0.6] — 2026-03-02

### Fixed
- Repository security scan false-negative
- Broken JSON report generation
- Duplicate state entries in status output

### Improved
- Unified fix handler scanner repository
- Auto-fix non-interactive compliance
- Status report determinism

### Removed
- Termux API

---

## [1.0.5] — 2026-01-19

### Fixed
- Repository security scan now correctly exports `WARNINGS`, `DANGERS`, and `SECURITY_STATE`
- `fix_preview.sh` now calls the correct `ai_explain` function
- `doctor_json.sh` and `doctor_json_ai.sh` `STATE_FILE` paths unified
- `install.sh` was not copying the `modules/` and `data/` directories
- `VERSION` file was out of sync with `version.sh`

### Added
- `tdoc doctor --json-ai` command in the main entrypoint
- Initialization of `SECURITY_STATE`, `WARNINGS`, `DANGERS` in `repo_security.sh`

---

## [1.0.4] — 2026-01-19
- Static diagnostic helper (offline)

## [1.0.3] — 2026-01-18
- UI display improvements

## [1.0.2] — 2026-01-18
- Man page and display fixes

## [1.0.1] — 2026-01-17
- Automated release pipeline

## [1.0.0] — 2026-01-16
- Initial release
