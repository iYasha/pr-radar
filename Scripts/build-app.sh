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
SHORT_VERSION="${SHORT_VERSION:-0.1.0}"   # CFBundleShortVersionString (env-overridable; release.sh sets it)
BUILD_VERSION="${BUILD_VERSION:-1}"       # CFBundleVersion (monotonic; bump per release)
MIN_MACOS="14.0"

# Sparkle auto-update: appcast feed + EdDSA public key (private key lives in the
# keychain; regenerate with Scripts/release.sh / generate_keys).
SU_FEED_URL="https://raw.githubusercontent.com/iYasha/pr-radar/main/appcast.xml"
SU_PUBLIC_ED_KEY="o5pi0q0j50wc++dJ9cMWH7U2MnAECaqB1W123DWqGaY="

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

# Embed Sparkle.framework (the executable links it as @rpath/Sparkle.framework/…)
# and add a Frameworks rpath so it resolves inside the bundle on any machine.
SPARKLE_SRC="$BIN_DIR/Sparkle.framework"
if [ -d "$SPARKLE_SRC" ]; then
  mkdir -p "$CONTENTS/Frameworks"
  cp -R "$SPARKLE_SRC" "$CONTENTS/Frameworks/"
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$CONTENTS/MacOS/$EXE_NAME" 2>/dev/null || true
else
  echo "⚠ Sparkle.framework not found at $SPARKLE_SRC — auto-update will not load"
fi

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
    <key>SUFeedURL</key>               <string>$SU_FEED_URL</string>
    <key>SUPublicEDKey</key>           <string>$SU_PUBLIC_ED_KEY</string>
    <key>SUEnableAutomaticChecks</key> <true/>
    <key>SUScheduledCheckInterval</key> <integer>86400</integer>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS/PkgInfo"

# --- ad-hoc sign ------------------------------------------------------------
# Sign inside-out: the embedded framework (and its nested XPC/helper bundles)
# first, then the app (which signs the rpath-patched executable and seals the
# framework). install_name_tool above invalidated the exe signature, so the app
# sign must come last.
echo "› codesign (ad-hoc)"
if [ -d "$CONTENTS/Frameworks/Sparkle.framework" ]; then
  codesign --force --sign - --timestamp=none --deep "$CONTENTS/Frameworks/Sparkle.framework"
fi
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --verbose "$APP" 2>&1 | sed 's/^/  /'

echo "✓ built $APP  ($SHORT_VERSION/$BUILD_VERSION)"
echo "  run:  open \"$APP\""
