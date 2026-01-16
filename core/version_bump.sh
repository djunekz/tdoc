#!/bin/bash
# ==============================
# TDOC Version Bumper
# ==============================

source "$TDOC_ROOT/core/version.sh"

bump_version() {
  local type="$1"

  IFS='.' read -r major minor patch <<< "$TDOC_VERSION"

  case "$type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch|"")
      patch=$((patch + 1))
      ;;
    *)
      echo "❌ Invalid bump type: $type"
      exit 1
      ;;
  esac

  NEW_VERSION="$major.$minor.$patch"
}

write_version_file() {
  cat > "$TDOC_ROOT/core/version.sh" <<EOF
#!/bin/bash
# ==============================
# TDOC Version (Auto Generated)
# ==============================

TDOC_NAME="$TDOC_NAME"
TDOC_VERSION="$NEW_VERSION"
TDOC_CODENAME="$TDOC_CODENAME"
TDOC_BUILD_DATE="$(date +%Y-%m-%d)"

export TDOC_NAME
export TDOC_VERSION
export TDOC_CODENAME
export TDOC_BUILD_DATE
EOF
}
