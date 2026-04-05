#!/bin/bash
# Generate all icon formats from icon.svg
# Run once: ./tools/generate-icons.sh
# Then commit the generated files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICON_DIR="$PROJECT_DIR/assets/icon"
SVG="$ICON_DIR/icon.svg"

if [ ! -f "$SVG" ]; then
  echo "Error: assets/icon/icon.svg not found"
  exit 1
fi

echo "Generating icons from icon.svg..."

# PNG (1024x1024) - used by Love2D window icon
if command -v rsvg-convert &> /dev/null; then
  rsvg-convert -w 1024 -h 1024 "$SVG" -o "$ICON_DIR/icon.png"
elif command -v magick &> /dev/null; then
  magick -background none "$SVG" -resize 1024x1024 "$ICON_DIR/icon.png"
else
  echo "Error: rsvg-convert or imagemagick required"
  echo "  brew install librsvg"
  exit 1
fi
echo "  Created: assets/icon.png (1024x1024)"

# ICO (Windows) - multiple sizes embedded
if command -v magick &> /dev/null; then
  magick "$ICON_DIR/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ICON_DIR/icon.ico"
  echo "  Created: assets/icon.ico"
elif command -v convert &> /dev/null; then
  convert "$ICON_DIR/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ICON_DIR/icon.ico"
  echo "  Created: assets/icon.ico"
else
  echo "  Skipped: icon.ico (imagemagick not found)"
fi

# ICNS (macOS)
if command -v iconutil &> /dev/null; then
  ICONSET="$ICON_DIR/Gridlock.iconset"
  mkdir -p "$ICONSET"
  sips -z 16 16     "$ICON_DIR/icon.png" --out "$ICONSET/icon_16x16.png"     > /dev/null
  sips -z 32 32     "$ICON_DIR/icon.png" --out "$ICONSET/icon_16x16@2x.png"  > /dev/null
  sips -z 32 32     "$ICON_DIR/icon.png" --out "$ICONSET/icon_32x32.png"     > /dev/null
  sips -z 64 64     "$ICON_DIR/icon.png" --out "$ICONSET/icon_32x32@2x.png"  > /dev/null
  sips -z 128 128   "$ICON_DIR/icon.png" --out "$ICONSET/icon_128x128.png"   > /dev/null
  sips -z 256 256   "$ICON_DIR/icon.png" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
  sips -z 256 256   "$ICON_DIR/icon.png" --out "$ICONSET/icon_256x256.png"   > /dev/null
  sips -z 512 512   "$ICON_DIR/icon.png" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
  sips -z 512 512   "$ICON_DIR/icon.png" --out "$ICONSET/icon_512x512.png"   > /dev/null
  sips -z 1024 1024 "$ICON_DIR/icon.png" --out "$ICONSET/icon_512x512@2x.png" > /dev/null
  iconutil -c icns "$ICONSET" -o "$ICON_DIR/icon.icns"
  rm -rf "$ICONSET"
  echo "  Created: assets/icon.icns"
else
  echo "  Skipped: icon.icns (macOS only)"
fi

# Android mipmap icons
# mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192
RESIZE_CMD=""
if command -v magick &> /dev/null; then
  RESIZE_CMD="magick"
elif command -v sips &> /dev/null; then
  RESIZE_CMD="sips"
fi

if [ -n "$RESIZE_CMD" ]; then
  ANDROID_DIR="$ICON_DIR/android"

  for entry in mipmap-mdpi:48 mipmap-hdpi:72 mipmap-xhdpi:96 mipmap-xxhdpi:144 mipmap-xxxhdpi:192; do
    folder="${entry%%:*}"
    size="${entry##*:}"
    dir="$ANDROID_DIR/$folder"
    mkdir -p "$dir"

    # Standard launcher icon
    if [ "$RESIZE_CMD" = "magick" ]; then
      magick "$ICON_DIR/icon.png" -resize "${size}x${size}" "$dir/ic_launcher.png"
    else
      cp "$ICON_DIR/icon.png" "$dir/ic_launcher.png"
      sips -z "$size" "$size" "$dir/ic_launcher.png" > /dev/null
    fi

    # Foreground for adaptive icons (108dp canvas, icon centered)
    fg_size=$((size * 108 / 48))
    if [ "$RESIZE_CMD" = "magick" ]; then
      magick "$ICON_DIR/icon.png" -resize "${size}x${size}" -gravity center -background none -extent "${fg_size}x${fg_size}" "$dir/ic_launcher_foreground.png"
    else
      cp "$ICON_DIR/icon.png" "$dir/ic_launcher_foreground.png"
      sips -z "$fg_size" "$fg_size" "$dir/ic_launcher_foreground.png" > /dev/null
    fi
  done

  echo "  Created: assets/android/mipmap-*/ic_launcher.png"
  echo "  Created: assets/android/mipmap-*/ic_launcher_foreground.png"
else
  echo "  Skipped: Android icons (imagemagick or sips not found)"
fi

echo ""
echo "Done! Commit the generated files to the repo."
