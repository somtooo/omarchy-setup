#!/bin/bash
# Regenerate the blurred login/lock screen backgrounds from your current
# Omarchy wallpaper. Run after `omarchy theme bg set <image>`.
# The SDDM copy needs no password: background.jpg in the installed theme is
# owned by the user (one-time setup: chown it, see login-and-lock-screens.md).
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

SDDM_BG="/usr/share/sddm/themes/macos/background.jpg"
if [[ -w $SDDM_BG ]]; then
  cp "$OUT_DIR/sddm-macos/background.jpg" "$SDDM_BG"
  echo "Wrote:"
  echo "  $USER_DIR/lock-blur.jpg            (lock screen — live now)"
  echo "  $SDDM_BG (login screen — live now)"
else
  echo "Wrote $USER_DIR/lock-blur.jpg and $OUT_DIR/sddm-macos/background.jpg," >&2
  echo "but $SDDM_BG is not user-writable; chown it to \$USER (see login-and-lock-screens.md)." >&2
  exit 1
fi
