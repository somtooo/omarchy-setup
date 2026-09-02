#!/bin/bash
# Regenerate the blurred login/lock screen backgrounds from your current
# Omarchy wallpaper. Run after `omarchy theme bg set <image>`,
# then copy the SDDM one into place (needs sudo):
#   sudo cp ~/devcave/login-customization/sddm-macos/background.jpg /usr/share/sddm/themes/macos/
set -euo pipefail

BG="$(readlink -f "$HOME/.local/state/omarchy/current/background")"
[[ -f $BG ]] || { echo "No current background found" >&2; exit 1; }
echo "Source wallpaper: $BG"

OUT_DIR="$HOME/devcave/login-customization"
USER_DIR="$HOME/.local/share/login-look"
mkdir -p "$USER_DIR"

# Lock screen (omarchy shell) — strong blur, darkened
magick "$BG" -resize 3840x3840^ -gravity center -extent 3840x3840 \
  -blur 0x24 -modulate 92 -quality 92 "$USER_DIR/lock-blur.jpg"

# SDDM greeter — strong blur, darkened
magick "$BG" -resize 2560x2560^ -gravity center -extent 2560x2560 \
  -blur 0x14 -modulate 90 -quality 90 "$OUT_DIR/sddm-macos/background.jpg"

echo "Wrote:"
echo "  $USER_DIR/lock-blur.jpg            (lock screen — live now)"
echo "  $OUT_DIR/sddm-macos/background.jpg (run the sudo cp above to update the login screen)"
