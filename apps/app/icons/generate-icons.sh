#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/templogo.png"

if [ ! -f "$SOURCE" ]; then
	echo "Error: templogo.png not found in $SCRIPT_DIR"
	exit 1
fi

echo "Generating icons from templogo.png..."

# PNG icons with specific sizes
declare -A PNGS=(
	["icon.png"]=512
	["128x128.png"]=128
	["128x128@2x.png"]=256
	["Square30x30Logo.png"]=30
	["Square44x44Logo.png"]=44
	["Square71x71Logo.png"]=71
	["Square89x89Logo.png"]=89
	["Square107x107Logo.png"]=107
	["Square142x142Logo.png"]=142
	["Square150x150Logo.png"]=150
	["Square284x284Logo.png"]=284
	["Square310x310Logo.png"]=310
	["StoreLogo.png"]=50
)

for file in "${!PNGS[@]}"; do
	size="${PNGS[$file]}"
	echo "  ${file} (${size}x${size})"
	convert "$SOURCE" -resize "${size}x${size}" "$SCRIPT_DIR/$file"
done

# ICO files (multiple sizes embedded)
echo "  icon.ico"
convert "$SOURCE" \
	-define icon:auto-resize=256,128,64,48,32,16 \
	"$SCRIPT_DIR/icon.ico"

echo "  favicon.ico"
convert "$SOURCE" \
	-define icon:auto-resize=64,48,32,16 \
	"$SCRIPT_DIR/favicon.ico"

# ICNS file (macOS)
echo "  icon.icns"
ICONSET_DIR=$(mktemp -d)/icon.iconset
mkdir -p "$ICONSET_DIR"
for size in 16 32 128 256 512; do
	convert "$SOURCE" -resize "${size}x${size}" "$ICONSET_DIR/icon_${size}x${size}.png"
	double=$((size * 2))
	convert "$SOURCE" -resize "${double}x${double}" "$ICONSET_DIR/icon_${size}x${size}@2x.png"
done

if command -v iconutil &>/dev/null; then
	iconutil -c icns "$ICONSET_DIR" -o "$SCRIPT_DIR/icon.icns"
elif command -v png2icns &>/dev/null; then
	png2icns "$SCRIPT_DIR/icon.icns" "$ICONSET_DIR"/icon_*.png 2>/dev/null || \
		echo "  Warning: png2icns failed, trying icotool fallback"
else
	echo "  Warning: Neither iconutil (macOS) nor png2icns (Linux) found."
	echo "  Generating icns via ImageMagick (may not be optimal)..."
	convert "$SOURCE" -resize 512x512 "$SCRIPT_DIR/icon.icns"
fi
rm -rf "$(dirname "$ICONSET_DIR")"

echo "Done! All icons generated."
