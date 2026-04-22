#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Generating app icon"
rm -rf build/AppIcon.iconset
mkdir -p build/AppIcon.iconset Resources
swift Tools/MakeIcon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

echo "==> Building (release)"
swift build -c release

APP="TypeGrab.app"
BUNDLE="build/$APP"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

cp ".build/release/TypeGrab" "$BUNDLE/Contents/MacOS/TypeGrab"
cp "Resources/Info.plist"     "$BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns"   "$BUNDLE/Contents/Resources/AppIcon.icns"

# Ad-hoc codesign so macOS remembers TCC permissions and SMAppService works.
codesign --force --deep --sign - "$BUNDLE"

echo "==> Built $BUNDLE"
echo "Run:  open $BUNDLE"
