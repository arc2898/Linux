#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC="$ROOT/assets/everlumen-wallpaper.svg"; OUT="$ROOT/assets/everlumen-wallpaper.png"
if command -v rsvg-convert >/dev/null 2>&1; then rsvg-convert -w 3840 -h 2160 -o "$OUT" "$SRC"
elif command -v magick >/dev/null 2>&1; then magick -background '#080811' "$SRC" -resize 3840x2160 "$OUT"
elif command -v convert >/dev/null 2>&1; then convert -background '#080811' "$SRC" -resize 3840x2160 "$OUT"
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import cairosvg' >/dev/null 2>&1; then python3 -c 'import cairosvg,sys; cairosvg.svg2png(url=sys.argv[1],write_to=sys.argv[2],output_width=3840,output_height=2160)' "$SRC" "$OUT"
else echo 'Install librsvg, ImageMagick, or Python CairoSVG to render wallpaper PNG.' >&2; exit 1; fi
echo "Rendered $OUT"
