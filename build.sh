#!/bin/bash
# Builds Sandman.app into ./build. Usage: ./build.sh [run|install]
# Sandman is deliberately NOT sandboxed: it has to read other apps' signatures.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Sandman"
APP="build/Sandman.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Sandman"
cp Support/Info.plist "$APP/Contents/Info.plist"
# Build the icon with Apple's own tools from the 1024px PNG; fall back to the committed .icns.
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
if command -v iconutil >/dev/null; then
  for size in 16 32 128 256 512; do
    sips -z $size $size Support/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size*2)) $((size*2)) Support/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
else
  cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
codesign --force --sign - --options runtime "$APP"
echo "Built $APP"

# Tell Launch Services about the bundle (and its icon) so Finder and the Dock don't show a
# generic executable after a rename or icon change.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
register() { touch "$1"; "$LSREGISTER" -f "$1" >/dev/null 2>&1 || true; }
register "$APP"

case "${1:-}" in
  run)     open "$APP" ;;
  install) rm -rf /Applications/Sandman.app && cp -R "$APP" /Applications/ \
             && register /Applications/Sandman.app && killall Dock 2>/dev/null; open /Applications/Sandman.app ;;
esac
