# TDOC — Changelog

All notable changes to TDOC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]
- Planned feature
- Documentation Updates
---

## [1.0.5] — 2026-01-19
### Fixed
- Repository security scan false-negative
- Broken JSON report generation
- Duplicate state entries in status output

### Improved
- Unified fix handler naming
- Auto-fix non-interactive compliance
- Status report determinism

### Removed
- jq dependency
- Unsafe JSON string concatenation

### Notes
This release focuses on internal correctness and upstream compliance.
---

## [1.0.4] - 2026-01-19
### What's New
AI : This is a static diagnostic helper.
It provides guidance based on predefined knowledge.
It is NOT a real AI
(all explanations are local and offline)

### Fixed
- Fixed repository check
- Fixed checking storage
- Fixed lib state location

### Update Documentation
- Change update information (CHANGELOG.md)
---

## [1.0.3] - 2026-01-18
### Added
- Planned feature (UI Display)
- Documentation updates
---

## [1.0.2] - 2026-01-18
### What's New
- Update install.sh and Uninstall.sh
- Update feature

### Fixed
- Fixed bug information display (termux version, name, double name)
- Fixed command not found scan
- Fixed bug status

### Added
- Man page
- Planned features / fixes for next release
- Improvements in AI explanations
- Additional repo and security checks
- Documentation updates

### Remove Feature
- Automated release pipeline in tool command
---

## [1.0.1] - 2026-01-17
### Added
- Automated release pipeline (bump version, GitHub tagging, release creation)
- Tarball packaging for distribution
- Minor UX improvements

---

## [1.0.0] - 2026-01-16
### Added
- Initial release of TDOC
- System scan for Storage, Repository, Python, NodeJS
- Manual & automatic fix mode
- Status & explain commands
- JSON output for doctor & security mode
- GitHub update command
- UX enhancements: colors, icons, spinners
- Professional README, LICENSE, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT
