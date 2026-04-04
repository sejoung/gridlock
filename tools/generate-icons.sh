#!/bin/bash
# Generate all icon formats from icon.svg
# Run once: ./tools/generate-icons.sh
# Then commit the generated files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_DIR/assets"
SVG="$ASSETS_DIR/icon.svg"

if [ ! -f "$SVG" ]; then
  echo "Error: assets/icon.svg not found"
  exit 1
fi

echo "Generating icons from icon.svg..."

# PNG (1024x1024) - used by Love2D window icon
if command -v rsvg-convert &> /dev/null; then
  rsvg-convert -w 1024 -h 1024 "$SVG" -o "$ASSETS_DIR/icon.png"
elif command -v magick &> /dev/null; then
  magick -background none "$SVG" -resize 1024x1024 "$ASSETS_DIR/icon.png"
else
  echo "Error: rsvg-convert or imagemagick required"
  echo "  brew install librsvg"
  exit 1
fi
echo "  Created: assets/icon.png (1024x1024)"

# ICO (Windows) - multiple sizes embedded
if command -v magick &> /dev/null; then
  magick "$ASSETS_DIR/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ASSETS_DIR/icon.ico"
  echo "  Created: assets/icon.ico"
elif command -v convert &> /dev/null; then
  convert "$ASSETS_DIR/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ASSETS_DIR/icon.ico"
  echo "  Created: assets/icon.ico"
else
  echo "  Skipped: icon.ico (imagemagick not found)"
fi

# ICNS (macOS)
if command -v iconutil &> /dev/null; then
  ICONSET="$ASSETS_DIR/Gridlock.iconset"
  mkdir -p "$ICONSET"
  sips -z 16 16     "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_16x16.png"     > /dev/null
  sips -z 32 32     "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_16x16@2x.png"  > /dev/null
  sips -z 32 32     "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_32x32.png"     > /dev/null
  sips -z 64 64     "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_32x32@2x.png"  > /dev/null
  sips -z 128 128   "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_128x128.png"   > /dev/null
  sips -z 256 256   "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
  sips -z 256 256   "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_256x256.png"   > /dev/null
  sips -z 512 512   "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
  sips -z 512 512   "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_512x512.png"   > /dev/null
  sips -z 1024 1024 "$ASSETS_DIR/icon.png" --out "$ICONSET/icon_512x512@2x.png" > /dev/null
  iconutil -c icns "$ICONSET" -o "$ASSETS_DIR/icon.icns"
  rm -rf "$ICONSET"
  echo "  Created: assets/icon.icns"
else
  echo "  Skipped: icon.icns (macOS only)"
fi

echo ""
echo "Done! Commit the generated files to the repo."
