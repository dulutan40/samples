#!/usr/bin/env bash
# Capture PNG screenshots from the booted iOS Simulator.
# Prerequisites: Simulator booted, app installed (e.g. flutter run once).
set -euo pipefail
OUT="${1:-store_assets/screenshots/ios_raw}"
mkdir -p "$OUT"
UDID="$(xcrun simctl list devices booted | grep -m1 'Booted' | grep -oE '[A-F0-9-]{36}' || true)"
if [[ -z "$UDID" ]]; then
  echo "No booted simulator. Boot one with: open -a Simulator"
  exit 1
fi
echo "Using booted device: $UDID"
for i in 01 02 03 04 05; do
  read -r -p "Navigate to screen $i, then press Enter to capture..."
  xcrun simctl io "$UDID" screenshot "$OUT/pong_ios_${i}.png"
  echo "Saved $OUT/pong_ios_${i}.png"
done
echo "Resize exports to App Store sizes in Figma or sips/ImageMagick before upload."
