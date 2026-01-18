#!/bin/bash
# ==============================
# TDOC GitHub Release Reset & Recreate
# ==============================

# CONFIG
GITHUB_REPO="djunekz/tdoc"           # owner/repo
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO"
CHANGELOG_FILE="CHANGELOG.md"
NEW_VERSION=$(grep -Eo '## \[1\.[0-9]+\.[0-9]+\]' "$CHANGELOG_FILE" | head -1 | tr -d '## []')
GITHUB_TOKEN="$GITHUB_TOKEN"         # Export your token first: export GITHUB_TOKEN=xxxx

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Please set GITHUB_TOKEN environment variable"
  exit 1
fi

echo "🔹 Resetting all Git tags..."
git tag -l | xargs -r git tag -d
git push origin --delete $(git tag -l) 2>/dev/null || true

echo "🔹 Deleting all GitHub releases..."
RELEASE_IDS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$GITHUB_API/releases" | jq -r '.[].id')
for id in $RELEASE_IDS; do
  echo "Deleting release ID: $id"
  curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" "$GITHUB_API/releases/$id"
done

echo "🔹 Creating new tag: $NEW_VERSION"
git add -A
git commit -m "chore(release): $NEW_VERSION" 2>/dev/null || true
git tag -a "v$NEW_VERSION" -m "TDOC $NEW_VERSION release"
git push origin main --tags

echo "🔹 Creating new GitHub release..."
RELEASE_BODY=$(awk '/## \['"$NEW_VERSION"'\]/,/^## \[/' "$CHANGELOG_FILE" | sed '$d' | sed '1d')
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"tag_name\":\"v$NEW_VERSION\",\"name\":\"v$NEW_VERSION\",\"body\":\"$RELEASE_BODY\",\"draft\":false,\"prerelease\":false}" \
     "$GITHUB_API/releases"

echo "✅ TDOC release reset and recreated successfully!"
