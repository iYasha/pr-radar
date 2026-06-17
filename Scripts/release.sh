#!/usr/bin/env bash
# Cut a PR Radar release: build the .app, EdDSA-sign it for Sparkle, publish a
# GitHub release with the zipped app, and update the appcast feed so already-
# installed copies auto-update.
#
#   Scripts/release.sh 0.2.0
#
# Prereqs:
#   - gh authenticated (gh auth status)
#   - Sparkle EdDSA private key in the login keychain (Scripts/build-app.sh's
#     SU_PUBLIC_ED_KEY must match; key created via generate_keys)
#   - swift package resolve has run (sign_update tool present)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${1:?usage: release.sh <version>   e.g. release.sh 0.2.0}"
TAG="v$VERSION"
REPO="iYasha/pr-radar"
ZIP="PRRadar-$VERSION.zip"
FEED="appcast.xml"
MIN_MACOS="14.0"
SIGN_TOOL=".build/artifacts/sparkle/Sparkle/bin/sign_update"

[ -x "$SIGN_TOOL" ] || { echo "✗ $SIGN_TOOL missing — run 'swift package resolve'"; exit 1; }
command -v gh >/dev/null || { echo "✗ gh CLI not found"; exit 1; }

# 1. Build the bundle stamped at this version.
echo "› building $VERSION"
SHORT_VERSION="$VERSION" BUILD_VERSION="$VERSION" Scripts/build-app.sh >/dev/null

# 2. Zip it (ditto keeps the .app wrapper, which Sparkle requires).
echo "› zipping $ZIP"
rm -f "dist/$ZIP"
ditto -c -k --keepParent "dist/PRRadar.app" "dist/$ZIP"

# 3. EdDSA-sign the archive.
echo "› signing"
SIG_LINE="$("$SIGN_TOOL" "dist/$ZIP")"          # sparkle:edSignature="…" length="…"
ED_SIG="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' <<<"$SIG_LINE")"
LENGTH="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' <<<"$SIG_LINE")"
[ -n "$ED_SIG" ] && [ -n "$LENGTH" ] || { echo "✗ signing failed: $SIG_LINE"; exit 1; }

DL_URL="https://github.com/$REPO/releases/download/$TAG/$ZIP"
PUBDATE="$(date -u '+%a, %d %b %Y %H:%M:%S +0000')"

# 4. Publish the GitHub release with the zip asset.
echo "› publishing GitHub release $TAG"
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "dist/$ZIP" --clobber
else
  gh release create "$TAG" "dist/$ZIP" --title "PR Radar $VERSION" --notes "PR Radar $VERSION"
fi

# 5. Regenerate the appcast — a single latest <item>; older clients update to it.
echo "› writing $FEED"
cat > "$FEED" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>PR Radar</title>
    <item>
      <title>$VERSION</title>
      <pubDate>$PUBDATE</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_MACOS</sparkle:minimumSystemVersion>
      <enclosure url="$DL_URL"
                 sparkle:edSignature="$ED_SIG"
                 length="$LENGTH"
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
XML

# 6. Commit + push the appcast so the raw URL serves the new version.
git add "$FEED"
git commit -m "Release $VERSION: update appcast"
git push origin main

echo "✓ released $VERSION"
echo "  asset:   $DL_URL"
echo "  appcast: https://raw.githubusercontent.com/$REPO/main/$FEED"
