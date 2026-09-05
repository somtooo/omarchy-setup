#!/bin/bash
# Regenerate the blurred login/lock screen backgrounds from your current
# Omarchy wallpaper. Run after `omarchy theme bg set <image>`.
# The SDDM copy needs no password: background.jpg in the installed theme is
# owned by the user (one-time setup: chown it, see login-and-lock-screens.md).
set -euo pipefail

STATE="$HOME/.local/state/omarchy/current"
CACHE_DIR="$HOME/.cache"
MARKER="$CACHE_DIR/login-bg-sync.last"

# Identity of the current wallpaper choice (source file + theme).
choice_key() {
  local bg
  bg="$(readlink -f "$STATE/background" 2>/dev/null || true)"
  printf '%s|%s|%s' "$bg" \
    "$(stat -c '%s:%Y' "$bg" 2>/dev/null || echo missing)" \
    "$(cat "$STATE/theme.name" 2>/dev/null || true)"
}

# Wait until the wallpaper choice is stable for 4s (cycling quickly through
# wallpapers costs one regeneration, not one per wallpaper). Give up waiting
# after ~40s and regenerate from whatever is current.
prev=""; stable=0
for _ in $(seq 1 40); do
  cur="$(choice_key)"
  if [[ $cur == "$prev" ]]; then
    stable=$((stable + 1))
    if ((stable >= 4)); then break; fi
  else
    stable=0; prev="$cur"
  fi
  sleep 1
done

# Serialize overlapping runs; skip if another run already handled this choice.
mkdir -p "$CACHE_DIR"
exec 9>"$CACHE_DIR/login-bg-sync.lock"
flock 9
if [[ -f $MARKER ]] && [[ $(cat "$MARKER") == "$(choice_key)" ]]; then
  echo "Backgrounds already current — nothing to do."
  exit 0
fi

BG="$(readlink -f "$STATE/background")"
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
  choice_key > "$MARKER"
  echo "Wrote:"
  echo "  $USER_DIR/lock-blur.jpg            (lock screen — live now)"
  echo "  $SDDM_BG (login screen — live now)"
else
  echo "Wrote $USER_DIR/lock-blur.jpg and $OUT_DIR/sddm-macos/background.jpg," >&2
  echo "but $SDDM_BG is not user-writable; chown it to \$USER (see login-and-lock-screens.md)." >&2
  exit 1
fi
