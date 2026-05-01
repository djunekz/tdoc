# TDOC — Termux Doctor

![License](https://img.shields.io/badge/license-MIT-green.svg?logo=github)
![Platform](https://img.shields.io/badge/platform-Termux-blue.svg?logo=Android)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg?logo=github)
![Version](https://img.shields.io/badge/version-2.0.0-blue.svg?logo=github)
[![Downloads](https://img.shields.io/github/downloads/djunekz/tdoc/total?style=for-the-badge.svg&logo=github)](https://github.com/djunekz/tdoc/releases)

---

## Table of Contents

- [About TDOC](#about-tdoc)
- [Features](#features)
- [Installation](#installation)
- [Commands](#commands)
- [Internationalization](#internationalization)
- [Plugin System](#plugin-system)
- [Security Model](#security-model)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## About TDOC

**TDOC** (Termux Doctor) is a powerful CLI tool to **diagnose, fix, and manage your Termux environment**.  
It is designed for:

- Detecting broken packages, storage, repository settings, and more
- Automatic or interactive fixes with user confirmation
- Generating JSON reports and live system monitoring
- Full internationalization support (English & Bahasa Indonesia)
- Professional UX with colors, icons, and spinners

TDOC is lightweight, open-source, and optimized for **Termux users and developers**.

---

## Features

- ✅ System scan (storage, repositories, Python, NodeJS, Git, etc.)
- ✅ Manual / automatic fixes (`tdoc fix`, `tdoc fix --auto`)
- ✅ Fix preview / dry-run before applying (`tdoc fix --preview`)
- ✅ Interactive fix for Python and Git (previously skipped silently)
- ✅ Ad-hoc package check (`tdoc check <package>`)
- ✅ Operation history viewer (`tdoc history`)
- ✅ Live continuous monitoring (`tdoc doctor --live`)
- ✅ Storage, network & CPU benchmark (`tdoc benchmark`)
- ✅ Status reports (`tdoc status`, `tdoc report`)
- ✅ Doctor JSON output (`tdoc doctor --json`, `tdoc doctor --json-ai`)
- ✅ Repository security scan (`tdoc security`, `tdoc security --json`)
- ✅ Internationalization — English & Bahasa Indonesia (`tdoc lang set id`)
- ✅ Plugin system — drop `.sh` files in `modules/` to add custom checks
- ✅ Professional CLI UX (colors, icons, spinners)

---

## Installation

```bash
pkg update && pkg upgrade
pkg install git curl tar
```

```bash
git clone https://github.com/djunekz/tdoc
cd tdoc
bash install.sh
```

The installer copies TDOC to `$PREFIX/lib/tdoc` and creates a symlink at `$PREFIX/bin/tdoc`.

---

## Commands

### Diagnosis

| Command | Description |
|---|---|
| `tdoc scan` | Full system scan |
| `tdoc status` | Show last scan status |
| `tdoc explain` | Detailed explanation of broken items |
| `tdoc check <package>` | Ad-hoc check for any package (binary, dpkg, apt-cache) |

### Fix

| Command | Description |
|---|---|
| `tdoc fix` | Interactive fix wizard |
| `tdoc fix --preview` | Preview what would be fixed (dry-run) |
| `tdoc fix --auto` | Non-interactive automatic fix |

### Reports & History

| Command | Description |
|---|---|
| `tdoc report` | Show raw state file |
| `tdoc history` | View scan & fix operation history |
| `tdoc doctor --json` | Full doctor report as JSON |
| `tdoc doctor --json-ai` | Doctor report with AI explanations as JSON |

### Monitoring & Tools

| Command | Description |
|---|---|
| `tdoc doctor --live [seconds]` | Continuous monitoring, re-scans every N seconds (default: 60) |
| `tdoc benchmark` | Measure storage write speed, mirror latency, CPU/RAM info |

### Security

| Command | Description |
|---|---|
| `tdoc security` | Repository security scan |
| `tdoc security --json` | Security scan as JSON |

### Language

| Command | Description |
|---|---|
| `tdoc lang list` | List available languages |
| `tdoc lang set <code>` | Set language permanently (saved to `~/.tdoc/config`) |
| `tdoc --lang <code> <cmd>` | One-shot language override per command |

### Other

| Command | Description |
|---|---|
| `tdoc version` | Show version info |
| `tdoc update` | Show update instructions |
| `tdoc help` | Show help menu |

---

## Internationalization

TDOC supports multiple display languages. Language is auto-detected from your system `$LANG` variable, or can be set manually.

```bash
# Set permanently
tdoc lang set id     # Bahasa Indonesia
tdoc lang set en     # English

# One-shot override (not saved)
tdoc --lang id scan

# Via environment variable
TDOC_LANG=id tdoc fix --auto

# Check current language
tdoc lang list
```

Language files are located in `lang/`. To add a new language, copy `lang/en.sh`, translate the values, and run `tdoc lang set <code>`.

---

## Plugin System

TDOC auto-loads any `.sh` file placed in the `modules/` directory. If a function named `check_<filename>()` is defined inside, it will be called automatically during `tdoc scan`.

```bash
# Example: modules/ruby.sh
check_ruby() {
  if command -v ruby >/dev/null 2>&1; then
    echo "Ruby=OK" >> "$STATE_FILE"
    print_ok "Ruby"
  else
    echo "Ruby=BROKEN" >> "$STATE_FILE"
    print_err "Ruby"
  fi
}
```

No changes to core files needed.

---

## Security Model

TDOC is designed to be safe by default:

- No root access required
- No background services or daemons
- No telemetry or network calls during scan
- No package installation or removal without explicit user confirmation
- Repository verification uses official Termux mechanisms only

TDOC does not modify system state unless explicitly instructed by the user.

Please report security issues privately as described in [SECURITY.md](SECURITY.md). Do not post exploits publicly.

---

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before submitting PRs or issues.

- Fork the repository
- Create a descriptive branch name
- Submit a PR with a detailed description
- Follow the existing coding style and versioning conventions

---

## License

TDOC is licensed under the **MIT License**.

For commercial or proprietary use, a separate commercial license is available.  
See [COMMERCIAL_LICENSE.md](COMMERCIAL_LICENSE.md).

---

## Contact

TDOC Project Team
- 📧 djunekz@protonmail.com
- 🌐 GitHub: https://github.com/djunekz/tdoc
