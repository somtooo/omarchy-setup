# Login & Lock Screen Customization

macOS-style login and lock screens for Omarchy 4. This covers four separate
pieces:

1. **SDDM login theme** (`sddm-macos-theme/`) — what you see at boot / after logout
2. **Lock screen plugin** (`lock-screen-plugin/`) — what you see when you lock (Super+Esc → Lock)
3. **Plymouth boot splash** (`plymouth-beautiful-theme/`) — what you see on fresh boot before SDDM (replaces the "Omarchy" logo with a glowing orb from your wallpaper)
4. **Background sync script** (`scripts/sync-login-bg.sh`) — regenerates blurred
   wallpapers for both screens from your current Omarchy wallpaper

Everything here is reversible. Nothing in `/usr/share/omarchy/` is modified.

---

## How the pieces fit

| | Boot splash | Login screen | Lock screen |
|---|---|---|---|
| Program | Plymouth | SDDM | Omarchy shell (Quickshell) |
| Theme location | `/usr/share/plymouth/themes/macos/` | `/usr/share/sddm/themes/macos/` | `~/.config/omarchy/plugins/som2.lock/` |
| Switch config | `plymouth-set-default-theme beautiful` + `limine-mkinitcpio` | `/etc/sddm.conf.d/10-theme.conf` → `Current=macos` | `omarchy plugin enable som2.lock` |
| Needs root? | Yes | Yes | No |
| When you see it | Fresh boot (before SDDM) | Logout / boot if autologin disabled | Lock |

> **Why you see "Omarchy" on fresh boot even after changing SDDM:** with
> autologin enabled (`/etc/sddm.conf.d/autologin.conf` has `User=som2`),
> SDDM is skipped on boot — you go straight from Plymouth → desktop.
> So the logo you see on boot is Plymouth, not SDDM. Fix Plymouth (section 4)
> to remove it. To see SDDM on every boot, disable autologin (see section 4).

---

## 1. Install the SDDM macOS theme

The theme files live in `sddm-macos-theme/` in this repo. Install them:

```bash
cd omarchy-setup
pkexec bash -c '
  mkdir -p /usr/share/sddm/themes/macos
  cp sddm-macos-theme/* /usr/share/sddm/themes/macos/
  chmod 755 /usr/share/sddm/themes/macos
  chmod 644 /usr/share/sddm/themes/macos/*
'
```

> Note: run the `pkexec` from inside the repo directory, or adjust the paths.
> `pkexec` pops up a GUI password prompt, so it works from agents/scripts too.

Generate the blurred background from your current wallpaper (needs ImageMagick)
and copy it into the theme:

```bash
magick "$(readlink -f ~/.local/state/omarchy/current/background)" \
  -resize 2560x2560^ -gravity center -extent 2560x2560 \
  -blur 0x14 -modulate 90 -quality 90 /tmp/sddm-background.jpg
pkexec cp /tmp/sddm-background.jpg /usr/share/sddm/themes/macos/background.jpg
```

Point SDDM at the new theme:

```bash
pkexec sed -i 's/^Current=.*/Current=macos/' /etc/sddm.conf.d/10-theme.conf
```

Verify before logging out (runs the greeter in a test window):

```bash
cd /usr/share/sddm/themes/macos && sddm-greeter --test-mode --theme .
```

Then log out (Super+Esc → Log Out) to see it live. No reboot needed.

**Revert:** `pkexec sed -i 's/^Current=.*/Current=omarchy/' /etc/sddm.conf.d/10-theme.conf`

> Hyprland shows a blue fallback greeter if the configured theme is missing or
> broken — that's the safety net, not a broken system. Fix the theme or switch
> `Current=` back and log out again.

---

## 2. Install the lock screen plugin

`lock-screen-plugin/` contains the customized clone of Omarchy's built-in
`omarchy.lock` plugin (blurred wallpaper, big clock/date, circular avatar,
frosted pill password field).

```bash
mkdir -p ~/.config/omarchy/plugins/som2.lock
cp omarchy-setup/lock-screen-plugin/* ~/.config/omarchy/plugins/som2.lock/
mkdir -p ~/.local/share/login-look
cp omarchy-setup/sddm-macos-theme/avatar.png ~/.local/share/login-look/
```

The LockView references two user assets:

- `~/.local/share/login-look/avatar.png` — circular avatar (256×256, transparent outside circle)
- `~/.local/share/login-look/lock-blur.jpg` — pre-blurred wallpaper, generated
  by `scripts/sync-login-bg.sh` (run it after changing your wallpaper)

Enable it (this disables the stock `omarchy.lock`):

```bash
omarchy plugin enable som2.lock
omarchy-shell shell rescanPlugins
```

If `omarchy plugin enable som2.lock` doesn't know the plugin yet, rescan first
and retry. Lock the screen (Super+Esc → Lock) to see it.

**Revert:** `omarchy plugin enable omarchy.lock` (the clone can stay in place).

### Why the lock background is pre-blurred (resume-from-suspend speed)

The stock plugin (and an earlier version of this clone) loaded the raw
wallpaper and applied a live GPU blur (`MultiEffect`, blurMax 128) **at lock
time** (`loadBackground: root.locked`). On resume-from-suspend that meant:
decode a 4K JPEG + build a big GPU blur graph on a just-woken GPU before the
first lock frame could commit — Hyprland shows its grey session-lock failsafe
for ~3-4 seconds in the meantime.

The clone now:

- shows `lock-blur.jpg` (blur baked in offline by ImageMagick) with **no
  runtime blur** — a plain decoded JPEG paints far sooner
- loads it **synchronously with `cache: true`**, and `Service.qml` sets
  `loadBackground: true` so the image is decoded when the shell starts, not
  when you lock
- adds a cheap translucent black overlay (`Qt.rgba(0,0,0,0.18)`) for
  legibility instead of the blur's brightness/contrast tweaks

Result: background, avatar, clock and password field all appear together on
wake with no grey flash.

---

## 3. Changing the background on both screens

```bash
omarchy theme bg set /path/to/image.jpg        # set desktop wallpaper
bash omarchy-setup/scripts/sync-login-bg.sh    # regenerate blurred versions
pkexec cp ~/devcave/login-customization/sddm-macos/background.jpg /usr/share/sddm/themes/macos/
```

(`sync-login-bg.sh` writes to `~/devcave/login-customization/` by default —
edit the `OUT_DIR` variable at the top if you keep this repo elsewhere.)

The lock screen now uses the pre-blurred `lock-blur.jpg` from the script, so
**both** screens need `sync-login-bg.sh` after a wallpaper change (the lock no
longer follows wallpaper changes automatically). A systemd path unit does this
for you — see below.

### Auto-regenerate on wallpaper change

`systemd/login-bg-sync.path` + `.service` watch
`~/.local/state/omarchy/current/background` and `theme.name`; whenever the
wallpaper/theme changes they re-run `sync-login-bg.sh` (with a 2s debounce).
Install:

```bash
mkdir -p ~/.config/systemd/user
cp omarchy-setup/systemd/login-bg-sync.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now login-bg-sync.path
```

The lock screen background updates automatically from then on. The SDDM
greeter background is also regenerated but still needs a one-time
`pkexec cp` into `/usr/share/sddm/themes/macos/` to go live (root-owned dir).

To change the avatar, replace `~/.local/share/login-look/avatar.png` (lock) and
`/usr/share/sddm/themes/macos/avatar.png` (login). Generate a circular one from
any square image:

```bash
magick input.png -resize 256x256 \
  \( -size 256x256 xc:none -fill white -draw 'circle 128,128 128,6' \) \
  -alpha off -compose CopyOpacity -composite avatar.png
```

---

## 4. Boot splash (Plymouth)

Omarchy shows a boot splash **before** SDDM. With autologin enabled (the default
at `/etc/sddm.conf.d/autologin.conf`), SDDM is skipped on fresh boot — the
password prompt you see is **Plymouth asking for the disk-encryption password**
(the disk is encrypted, so this prompt always appears). That is why the stock
"Omarchy" logo showed even after the SDDM theme was changed.

`plymouth-beautiful-theme/` replaces it: stock Omarchy splash script (proven
code) with the logo swapped for a glowing orb cropped from your wallpaper,
a frosted-glass pill password field, and a soft white progress bar. All PNGs —
Plymouth **cannot load JPGs**, which is what broke an earlier attempt.

```bash
# Install theme files
pkexec bash -c 'mkdir -p /usr/share/plymouth/themes/beautiful && cp plymouth-beautiful-theme/* /usr/share/plymouth/themes/beautiful/ && chmod 644 /usr/share/plymouth/themes/beautiful/*'

# Activate and rebuild the boot image (Omarchy uses UKIs via limine-mkinitcpio;
# plymouth-set-default-theme --rebuild-initrd does NOT work here — no mkinitcpio presets)
plymouth-set-default-theme beautiful
pkexec limine-mkinitcpio
```

Revert:

```bash
pkexec bash -c 'plymouth-set-default-theme omarchy && limine-mkinitcpio'
```

To regenerate the orb from a new wallpaper:

```bash
# 720px orb (Plymouth scales it to 340px); adjust the crop offsets to centre the subject.
# Negative offsets shift the crop window left/up from centre; check the result visually.
magick "$(readlink -f ~/.local/state/omarchy/current/background)" -filter Lanczos -resize 720x720^ -gravity center -crop 720x720-320-40 +repage \
  \( -size 720x720 xc:none -fill white -draw 'circle 360,360 360,40' \) -compose CopyOpacity -composite /tmp/orb.png
pkexec bash -c 'cp /tmp/orb.png /usr/share/plymouth/themes/beautiful/orb.png && limine-mkinitcpio'
```

Note: ImageMagick trims fully-transparent edges, so the saved file may be slightly smaller
than 720×720 — harmless. The current orb (from `1-quattro.jpg`) uses `-320-40` to centre the car.

To disable autologin and see the SDDM login on every boot (you will then type
two passwords: disk + user):

```bash
pkexec bash -c 'printf "# autologin disabled\n" > /etc/sddm.conf.d/autologin.conf'
```

## Files in this repo

```
plymouth-beautiful-theme/  Plymouth boot splash (Quattro orb, frosted pill field)
  beautiful.plymouth     theme metadata
  beautiful.script       stock splash script, logo swapped for orb
  orb.png                glowing orb cropped from wallpaper (regenerate per-wallpaper)
  entry/bullet/lock/progress_*.png  frosted-glass UI assets
sddm-macos-theme/        SDDM theme (QML + assets; background.jpg generated by script)
  Main.qml               macOS-style greeter: blurred bg, avatar, pill password field
  metadata.desktop       SDDM theme metadata
  theme.conf             theme settings (empty defaults)
  avatar.png             circular avatar
lock-screen-plugin/      clone of omarchy.lock, macOS-styled
  LockView.qml           clock/date, avatar, frosted pill field over blurred wallpaper
  manifest.json          plugin manifest (id: som2.lock, clonedFrom: omarchy.lock)
scripts/
  sync-login-bg.sh       regenerate blurred backgrounds from current wallpaper
```
