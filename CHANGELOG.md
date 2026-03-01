# TDOC — Changelog

All notable changes to TDOC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]
- Planned features
- Documentation updates

---

## [1.0.5] — 2026-01-19
### Fixed
- Repository security scan now correctly exports WARNINGS, DANGERS, SECURITY_STATE variables
- `fix_preview.sh` used undefined `ai_explain_item` — fixed to use `ai_explain`
- `doctor_json.sh` and `doctor_json_ai.sh` STATE_FILE path inconsistency (was pointing to `$TDOC_ROOT/data/state.env`, now unified to `$PREFIX/var/lib/tdoc/state.env`)
- `install.sh` was not copying `modules/` and `data/` directories
- `VERSION` file out of sync with `version.sh`
- `version.sh` had dynamic `date` call causing inconsistent build date and duplicate `tdoc_version_ui` function

### Added
- `tdoc doctor --json-ai` command routed in main `tdoc` entrypoint
- `SECURITY_STATE`, `WARNINGS`, `DANGERS` properly initialized in `repo_security.sh`
- `PREFIX` fallback in `install.sh` for environments without `$PREFIX` set

### Removed
- `core/ai_helper.sh` — duplicate of `ai_engine.sh` + `ai_explain.sh`

### Improved
- Unified `STATE_FILE` path across all core scripts
- `install.sh` now creates `$PREFIX/var/lib/tdoc` state directory on install

---

## [1.0.4] - 2026-01-19
### What's New
- AI: Static diagnostic helper (offline, no real AI)

### Fixed
- Repository check
- Storage check
- Lib state location

---

## [1.0.3] - 2026-01-18
### Added
- Planned feature (UI Display)
- Documentation updates

---

## [1.0.2] - 2026-01-18
### What's New
- Updated install.sh and uninstall.sh
- Updated features

### Fixed
- Bug: information display (termux version, name, double name)
- Command not found on scan
- Bug: status display

### Added
- Man page
- Improvements in AI explanations
- Additional repo and security checks
- Documentation updates

---

## [1.0.1] - 2026-01-17
### Added
- Automated release pipeline
- Tarball packaging for distribution
- Minor UX improvements

---

## [1.0.0] - 2026-01-16
### Added
- Initial release of TDOC
- System scan: Storage, Repository, Python, NodeJS
- Manual & automatic fix mode
- Status & explain commands
- JSON output for doctor & security mode
- UX: colors, icons, spinners
