#!/bin/bash
# Keep the blurred login/lock backgrounds converged with the current Omarchy
# wallpaper. Triggered by login-bg-sync.path on every wallpaper/theme change.
#
# How it converges: concurrent runs serialize on a lock, and each run
# re-reads the current wallpaper until the outputs match it. Work starts
# immediately and always targets the latest wallpaper, so no matter how fast
# wallpapers change, the screens end up showing the settled one. The
# user-owned outputs are published with atomic renames, so readers never see
# half-written files.
#
# The SDDM copy needs no password: background.jpg in the installed theme is
# owned by the user (one-time setup: chown it, see login-and-lock-screens.md).
set -euo pipefail

STATE="$HOME/.local/state/omarchy/current"
CACHE="$HOME/.cache"
STAMP="$CACHE/login-bg-sync.stamp"
LOCK="$CACHE/login-bg-sync.lock"

OUT_DIR="$HOME/devcave/login-customization"
USER_DIR="$HOME/.local/share/login-look"
SDDM_BG="/usr/share/sddm/themes/macos/background.jpg"

mkdir -p "$CACHE" "$USER_DIR" "$OUT_DIR/sddm-macos"

# One writer at a time, held from the first read to process exit. A trigger
# that arrives mid-run waits here, then re-reads below — so every change is
# seen by at least one run and none is missed.
exec 9>"$LOCK"
flock 9

# Tell the running shell to drop its cached lock background and load the new
# file. Must run after publishing (never before). Harmless if the shell or
# the lock plugin isn't running.
notify_shell() {
  omarchy-shell -q lock reloadBackground >/dev/null 2>&1 || true
}

render_login_backgrounds() {
  local bg=$1 tmp
  tmp="$(mktemp -d "$CACHE/login-bg-sync.XXXXXX")"
  trap "rm -rf '$tmp'" EXIT

  # Lock screen (omarchy shell) — strong blur, darkened
  magick "$bg" -resize 3840x3840^ -gravity center -extent 3840x3840 \
    -blur 0x24 -modulate 92 -quality 92 "$tmp/lock-blur.jpg"

  # SDDM greeter — strong blur, darkened
  magick "$bg" -resize 2560x2560^ -gravity center -extent 2560x2560 \
    -blur 0x14 -modulate 90 -quality 90 "$tmp/sddm-background.jpg"

  mv "$tmp/lock-blur.jpg" "$USER_DIR/lock-blur.jpg"
  mv "$tmp/sddm-background.jpg" "$OUT_DIR/sddm-macos/background.jpg"
  # The theme directory is root-owned, so this overwrites the user-owned file
  # in place rather than renaming over it.
  if ! cp "$OUT_DIR/sddm-macos/background.jpg" "$SDDM_BG" 2>/dev/null; then
    echo "$SDDM_BG is not user-writable; chown it to \$USER (see login-and-lock-screens.md)." >&2
    exit 1
  fi

  echo "Live now:"
  echo "  $USER_DIR/lock-blur.jpg (lock screen)"
  echo "  $SDDM_BG (login screen)"
}

rendered=0
while true; do
  bg="$(readlink -f "$STATE/background")"
  [[ -f $bg ]] || { echo "No current background found: $bg" >&2; exit 1; }
  key="$bg $(stat -c '%s %Y' "$bg" 2>/dev/null || echo missing) $(cat "$STATE/theme.name" 2>/dev/null || echo unknown)"

  if [[ $(cat "$STAMP" 2>/dev/null || true) == "$key" ]]; then
    if ((rendered)); then notify_shell; fi
    echo "Login backgrounds already match the current wallpaper — nothing to do."
    exit 0
  fi

  echo "Syncing login backgrounds from: $bg"
  render_login_backgrounds "$bg"
  printf '%s\n' "$key" > "$STAMP"
  rendered=1
done
