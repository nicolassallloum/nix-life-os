#!/usr/bin/env bash

set -e

ROOT="/u01/nix-life-os/frontend"
LOGO="$ROOT/src/assets/brand/nix-life-os-logo-1024.png"
OUT="$ROOT/public/splash"

mkdir -p "$OUT"

generate_splash () {
  WIDTH=$1
  HEIGHT=$2
  FILE=$3

  convert -size ${WIDTH}x${HEIGHT} gradient:"#050816-#0f172a" \
    \( "$LOGO" -resize $((WIDTH / 4))x$((WIDTH / 4)) \) \
    -gravity center \
    -composite \
    "$OUT/$FILE"
}

generate_splash 640 1136 splash-640x1136.png
generate_splash 750 1334 splash-750x1334.png
generate_splash 828 1792 splash-828x1792.png
generate_splash 1125 2436 splash-1125x2436.png
generate_splash 1170 2532 splash-1170x2532.png
generate_splash 1179 2556 splash-1179x2556.png
generate_splash 1242 2688 splash-1242x2688.png
generate_splash 1284 2778 splash-1284x2778.png
generate_splash 1290 2796 splash-1290x2796.png
generate_splash 1536 2048 splash-1536x2048.png
generate_splash 1668 2224 splash-1668x2224.png
generate_splash 1668 2388 splash-1668x2388.png
generate_splash 2048 2732 splash-2048x2732.png

echo "Splash screens generated successfully."
