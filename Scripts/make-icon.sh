#!/usr/bin/env bash
# Regenerate Scripts/AppIcon.icns from AppIconView (Sources/PRRadar/Design/AppIcon.swift).
# Run only when the icon design changes; build-app.sh just copies the committed .icns.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WORK="$(mktemp -d -t AppIcon)"
MASTER="$WORK/AppIcon-1024.png"
ISET="$WORK/AppIcon.iconset"
mkdir -p "$ISET"
trap 'rm -rf "$WORK"' EXIT

echo "› rendering 1024 master via the app"
swift build -c debug >/dev/null
PRRADAR_ICON="$MASTER" .build/debug/PRRadar
[ -s "$MASTER" ] || { echo "✗ master render failed"; exit 1; }

echo "› slicing iconset"
for s in 16 32 128 256 512; do
  sips -z "$s" "$s" "$MASTER" --out "$ISET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z "$d" "$d" "$MASTER" --out "$ISET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$ISET" -o Scripts/AppIcon.icns
echo "✓ wrote Scripts/AppIcon.icns"
