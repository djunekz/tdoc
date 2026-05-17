# TDOC — Termux Doctor

![License](https://img.shields.io/badge/license-MIT-green.svg?logo=github)<br>
![Platform](https://img.shields.io/badge/platform-Termux-blue.svg?logo=Android)<br>
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg?logo=github)<br>
[![Version](https://img.shields.io/github/v/release/djunekz/tdoc)](https://github.com/djunekz/tdoc/releases/latest)<br>
[![Downloads](https://img.shields.io/github/downloads/djunekz/tdoc/total?style=for-the-badge.svg&logo=github)](https://github.com/djunekz/tdoc/releases)<br>
[![Shell](https://img.shields.io/badge/language-Bash%20Shell-4EAA25?style=for-the-badge.svg&logo=gnu-bash)](https://github.com/djunekz/tdoc)<br>
[![GitHub Stars](https://img.shields.io/github/stars/djunekz/tdoc)](https://github.com/djunekz/tdoc/stargazers)<br>

---

## Table of Contents

- [About TDOC](#about-tdoc)
- [Features](#features)
- [Installation](#installation)
- [Commands](#commands)
- [Repository Code Scanner](#repository-code-scanner)
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
- **Scanning project repositories for bugs, syntax errors, and misconfigurations**
- Full internationalization support (English & Bahasa Indonesia)
- Professional UX with colors, icons, and spinners

TDOC is lightweight, open-source, and optimized for **Termux users and developers**.

---

## Features

- ✅ System scan (storage, repositories, Python, NodeJS, Git, etc.)
- ✅ **Repository code scan — bugs, syntax errors, tracebacks across all languages** (`tdoc repo-scan`)
- ✅ **Auto code scan when running `tdoc scan` inside a project folder**
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
| `tdoc scan` | Full system scan. Also auto-runs code scan if inside a project folder |
| `tdoc repo-scan` | Scan current project folder for bugs, syntax errors, and tracebacks |
| `tdoc diagnose [error]` | Diagnose a specific error message or symptom |
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
| `tdoc checkup` | Full shareable health report (device, tools, scan state) |
| `tdoc checkup --save` | Save checkup report to `~/.tdoc/checkup_<timestamp>.txt` |
| `tdoc checkup --json` | Checkup report as JSON |
| `tdoc history` | View scan & fix operation history |
| `tdoc doctor --json` | Full doctor report as JSON |
| `tdoc doctor --json-ai` | Doctor report with AI explanations as JSON |

### Monitoring & Tools

| Command | Description |
|---|---|
| `tdoc doctor --live [seconds]` | Continuous monitoring, re-scans every N seconds (default: 60) |
| `tdoc watch [seconds]` | Alias for `tdoc doctor --live` |
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

## Repository Code Scanner

`tdoc repo-scan` scans your entire project directory for bugs, syntax errors, deprecated patterns, and traceback logs — without needing any external linters installed.

### Smart project detection

TDOC automatically detects whether you are inside a project folder by looking for common markers (`.git`, `Dockerfile`, `package.json`, `Cargo.toml`, `setup.py`, `pyproject.toml`, `requirements.txt`, `Makefile`, `docker-compose.yml`, `.github`, `go.mod`, `composer.json`).

- **Inside a project folder** — scans the current directory tree
- **Outside a project / at `$HOME`** — scans `$HOME`
- **Running `tdoc scan`** — if a project marker is found, the code scan runs automatically after the system scan

```bash
# Scan the project you are currently in
cd ~/projects/my-app
tdoc repo-scan

# Or just run the normal scan — code scan fires automatically
tdoc scan
```

### Supported file types

| Type | Files | What is checked |
|---|---|---|
| Python | `.py` | `SyntaxError`, `IndentationError` via `py_compile` |
| Shell / Bash | `.sh`, `.bash`, shebang executables | Full syntax via `bash -n` / `sh -n` |
| Perl | `.pl` | Syntax via `perl -c` |
| JavaScript | `.js`, `.mjs`, `.cjs` | Syntax via `node --check` |
| TypeScript | `.ts` | Type errors via `tsc --noEmit` (if `tsc` is available) |
| YAML | `.yml`, `.yaml` | Parse errors + GitHub Actions workflow lint |
| JSON | `.json` | Parse errors |
| TOML | `.toml` | Parse errors via `tomllib` |
| Dockerfile | `Dockerfile*` | Missing `FROM`, deprecated `MAINTAINER`, `sudo`, `ADD` misuse, `apt-get` without `-y` |
| Python deps | `requirements*.txt` | Unpinned versions, format errors |
| Environment | `.env`, `.env.*` | `KEY=VALUE` format, potential committed secrets |
| Rust | `src/**/*.rs` | `cargo check` (if `cargo` is available) |
| Makefile | `Makefile` | TAB-vs-spaces on recipe lines |
| Markdown | `.md` | Unclosed frontmatter, empty image/link refs |
| Logs | `.log`, `.out`, `.err` | 20+ traceback/error patterns (Python, Rust, Node, shell) |

### GitHub Actions extra lint

When scanning `.github/workflows/*.yml`, TDOC additionally checks for:

- Missing `on:` trigger or `jobs:` block
- Deprecated `set-output` command (use `$GITHUB_OUTPUT` instead)
- Deprecated `save-state` command (use `$GITHUB_STATE` instead)
- Unpinned `actions/checkout` (no version tag)

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

Please report security issues privately as described in [SECURITY](SECURITY.md). Do not post exploits publicly.

---

## Contributing

We welcome contributions! Please read [CONTRIBUTING](CONTRIBUTING.md) and [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md) before submitting PRs or issues.

- Fork the repository
- Create a descriptive branch name
- Submit a PR with a detailed description
- Follow the existing coding style and versioning conventions

---

## License

TDOC is licensed under the **MIT License**.

For commercial or proprietary use, a separate commercial license is available.  
See [COMMERCIAL_LICENSE](COMMERCIAL_LICENSE.md).

---

## Keywords

termux fix broken packages · termux repair tool · termux diagnostic CLI ·
android terminal doctor · bash system scanner · termux package manager fix ·
termux environment check · CLI linter android · tdoc termux · shell script debugger android

---

## Contact

TDOC Project Team
- 📧 Email Contact Support: gab288.gab288@passinbox.com
- 🌐 GitHub: [TDOC - Termux Doctor](https://github.com/djunekz/tdoc)
