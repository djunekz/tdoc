# TDOC — Changelog

All notable changes to TDOC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
