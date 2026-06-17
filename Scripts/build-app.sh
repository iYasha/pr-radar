#!/usr/bin/env bash
# Assemble PR Radar into a double-clickable, dockless .app bundle and ad-hoc sign it.
#
#   Scripts/build-app.sh            # release build → dist/PRRadar.app
#   Scripts/build-app.sh --debug    # debug build (faster, for local checks)
#
# Output: dist/PRRadar.app  (ad-hoc signed; runs on this Mac and others without
# a Developer ID, modulo the first-launch Gatekeeper right-click→Open).

set -euo pipefail

# --- config -----------------------------------------------------------------
APP_NAME="PR Radar"          # display name (Finder)
EXE_NAME="PRRadar"           # SPM executable / CFBundleExecutable
BUNDLE_ID="com.simantiev.prradar"
SHORT_VERSION="0.1.0"        # CFBundleShortVersionString (user-facing)
BUILD_VERSION="1"            # CFBundleVersion (monotonic; bump per release)
MIN_MACOS="14.0"

# --- locate repo root -------------------------------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIG="release"
[ "${1:-}" = "--debug" ] && CONFIG="debug"

echo "› swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN="$BIN_DIR/$EXE_NAME"
[ -x "$BIN" ] || { echo "✗ executable not found at $BIN"; exit 1; }

# --- assemble bundle --------------------------------------------------------
APP="dist/$EXE_NAME.app"
CONTENTS="$APP/Contents"
echo "› assembling $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources/Fonts"

cp "$BIN" "$CONTENTS/MacOS/$EXE_NAME"

# Fonts: copy out of the SPM resource bundle into Contents/Resources/Fonts so
# ATSApplicationFontsPath can auto-register them (and the in-app loader finds them).
FONT_SRC="$BIN_DIR/${EXE_NAME}_${EXE_NAME}.bundle/Fonts"
if [ -d "$FONT_SRC" ]; then
  cp "$FONT_SRC"/*.ttf "$CONTENTS/Resources/Fonts/"
else
  echo "⚠ font source $FONT_SRC missing — fonts will fall back to system"
fi

# App icon (regenerate with Scripts/make-icon.sh when the design changes).
ICON_SRC="$ROOT/Scripts/AppIcon.icns"
HAS_ICON=0
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$CONTENTS/Resources/AppIcon.icns"
  HAS_ICON=1
else
  echo "⚠ $ICON_SRC missing — run Scripts/make-icon.sh; bundle will use the generic icon"
fi

# --- Info.plist -------------------------------------------------------------
ICON_KEY=""
[ "$HAS_ICON" = "1" ] && ICON_KEY="
    <key>CFBundleIconFile</key>        <string>AppIcon</string>"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>      <string>$EXE_NAME</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$SHORT_VERSION</string>
    <key>CFBundleVersion</key>         <string>$BUILD_VERSION</string>
    <key>LSMinimumSystemVersion</key>  <string>$MIN_MACOS</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHighResolutionCapable</key> <true/>
    <key>ATSApplicationFontsPath</key> <string>Fonts</string>$ICON_KEY
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS/PkgInfo"

# --- ad-hoc sign ------------------------------------------------------------
echo "› codesign (ad-hoc)"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --verbose "$APP" 2>&1 | sed 's/^/  /'

echo "✓ built $APP  ($SHORT_VERSION/$BUILD_VERSION)"
echo "  run:  open \"$APP\""
