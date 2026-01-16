#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Full Release Pipeline
# ==============================

# Set TDOC_ROOT → folder release.sh berada
TDOC_ROOT="$(cd "$(dirname "$0")" && pwd)"
export TDOC_ROOT

# Source core scripts
source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/version.sh"
source "$TDOC_ROOT/core/bump_version.sh"

print_header "🚀 TDOC Release Pipeline"
echo

# -----------------------------
# 1️⃣ Bump version & update CHANGELOG
# -----------------------------
spinner_start "Bumping version & updating CHANGELOG"
bash "$TDOC_ROOT/core/bump_version.sh"
spinner_stop
print_ok "Version bumped to $TDOC_VERSION"

# -----------------------------
# 2️⃣ Git commit & tag
# -----------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    spinner_start "Committing version bump"
    git add "$TDOC_ROOT/core/version.sh" "$TDOC_ROOT/CHANGELOG.md"
    git commit -m "chore: release v$TDOC_VERSION" >/dev/null 2>&1
    git tag -a "v$TDOC_VERSION" -m "Release v$TDOC_VERSION" >/dev/null 2>&1
    spinner_stop
    print_ok "Git commit & tag created"
else
    print_warn "Not a git repo: skipping commit & tag"
fi

# -----------------------------
# 3️⃣ Build release package
# -----------------------------
RELEASE_DIR="$HOME/tdoc-release"
mkdir -p "$RELEASE_DIR"
spinner_start "Packaging release tarball"
cp -r "$TDOC_ROOT"/* "$RELEASE_DIR/"
TARBALL="$HOME/tdoc-v$TDOC_VERSION.tar.gz"
tar -czf "$TARBALL" -C "$RELEASE_DIR" .
spinner_stop
print_ok "Release tarball created: $TARBALL"

# -----------------------------
# 4️⃣ Push to GitHub
# -----------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    spinner_start "Pushing commits & tags to GitHub"
    git push >/dev/null 2>&1
    git push --tags >/dev/null 2>&1
    spinner_stop
    print_ok "GitHub updated with v$TDOC_VERSION"
else
    print_warn "Not a git repo: skipping GitHub push"
fi

# -----------------------------
# 5️⃣ Optional: GitHub Release (manual)
# -----------------------------
echo
echo "Next step: create a GitHub Release"
echo "Upload tarball: $TARBALL"
echo "Tag: v$TDOC_VERSION"

print_ok "✅ TDOC release pipeline finished"
