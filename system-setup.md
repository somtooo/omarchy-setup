# Omarchy System Setup Guide

A setup guide for Omarchy 4. Omarchy 4 uses Hyprland Lua user overrides and a
Quickshell-based desktop shell. Do not copy the old Waybar, SwayOSD, hypridle,
or custom lid-switch instructions from older Omarchy releases.

---

## Table of Contents

1. [Initial Software Installation](#initial-software-installation)
2. [Keyboard Configuration](#keyboard-configuration)
3. [Restore Configurations](#restore-configurations)
4. [Hyprland Display Management](#hyprland-display-management)
5. [UI Customization](#ui-customization)
6. [Window Manager Configuration](#window-manager-configuration)
7. [Login and Lock Screens](#login-and-lock-screens)
8. [System Services](#system-services) — includes macOS-style safe sleep (19) and keyboard backlight idle-off (19b)
9. [Backup Configuration](#backup-configuration)
10. [Development Tools](#development-tools)
11. [Audio Configuration](#audio-configuration)

---

## Initial Software Installation

### 1. Install Google Chrome

Download and install Google Chrome browser.

### 2. Install Warp Terminal

Install Warp terminal **before** running OS updates:

```bash
curl -L -O "https://releases.warp.dev/stable/v0.2026.02.04.08.20.stable_03/warp-terminal-v0.2026.02.04.08.20.stable_03-1-x86_64.pkg.tar.zst"
```

---

## Keyboard Configuration

### 3. Setup keyd for macOS-style Keyboard Mapping

Install and configure keyd to remap keyboard controls:

```bash
yay -S keyd
sudo mkdir -p /etc/keyd
```

Create the configuration file:

```bash
sudo tee /etc/keyd/default.conf << 'EOF'
[ids]
*

[main]
leftcontrol = leftmeta
leftmeta = leftalt
leftalt = leftcontrol

rightcontrol = rightmeta
rightmeta = rightalt
rightalt = rightcontrol
EOF
```

Enable and start the service:

```bash
sudo systemctl enable --now keyd
sudo keyd reload
```

### 3b. Map the ASUS Fn keys that emit fake combos

The G16's EC sends some Fn keys as hardcoded Windows key combos rather than
dedicated keycodes. Fn+F6 (the "screenshot" keycap) arrives as
**Shift+Alt+S** (the Windows snipping-tool shortcut). Map it to the Omarchy
screenshot in `~/.config/hypr/bindings.lua` (PRINT stays bound for external
keyboards):

```lua
o.bind("SHIFT + ALT + S", "Screenshot", "omarchy-capture-screenshot")
```

Fn+F2/F3 (keyboard backlight) are different: the EC handles them entirely in
hardware and sends nothing to Linux — see [19b](#19b-keyboard-backlight-on-while-typing-off-when-idle-asus).

---

## Restore Configurations

### 4. Restore Dotfiles

Restore dotfiles or full home directory from your backup location.

---

## Hyprland Display Management

### 5. Use Omarchy 4 Lid and Sleep Handling

Omarchy 4 handles lid events, clamshell mode, display reconciliation, and
sleep locking through its built-in Hyprland bindings and system helpers. Do
not create a custom lid script, add legacy `bindl` rules, or run the old idle
daemon for this purpose.

The native bindings call:

- `omarchy-system-lid-close` when the lid closes
- `omarchy-hyprland-monitor-clamshell` when the lid opens
- `omarchy-system-sleep-monitor` to lock before suspend

Inspect the active bindings and sleep monitor with:

```bash
omarchy menu keybindings --print
pgrep -a omarchy-system-sleep-monitor
```

### 6. Configure Monitors

Omarchy 4 monitor overrides belong in `~/.config/hypr/monitors.lua`:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
```

List connected monitors and supported modes with:

```bash
hyprctl monitors all
```

Do not edit `/usr/share/omarchy/` or the generated defaults under
`~/.local/share/omarchy/`.

---

## UI Customization

### 7. Install Inter Font

Install the Inter font family for system-wide use.

### 8. Configure Font Rendering

Create or edit `~/.config/fontconfig/fonts.conf` and add the following inside the `<fontconfig>` block:

```xml
<!-- Font rendering settings for macOS-like appearance -->
<match target="pattern">
  <edit name="antialias" mode="assign"><bool>true</bool></edit>
  <edit name="hinting" mode="assign"><bool>true</bool></edit>
  <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
  <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  <edit name="rgba" mode="assign"><const>rgb</const></edit>
  <edit name="stem-darkening" mode="assign"><bool>true</bool></edit>
  <edit name="stemdarkening" mode="assign"><bool>true</bool></edit>
</match>
```

### 9. Install Icon Theme

Install Colloid icon theme from: https://github.com/vinceliuice/Colloid-icon-theme

This repository is already cloned at `~/devcave/Colloid-icon-theme`. Install the
user icon theme without `sudo`:

```bash
cd ~/devcave/Colloid-icon-theme
./install.sh
```

### 10. Configure GTK Theme Settings

Install and use nwg-look:

- Set default font to **Inter**
- Enable all antialiasing options
- Set icon theme to **Colloid**

For Omarchy themes, keep a small user overlay so theme changes do not restore
the stock Yaru icon theme. For example, create
`~/.config/omarchy/themes/tokyo-night/icons.theme` containing:

```text
Colloid-Dark
```

Re-apply the theme after creating the overlay:

```bash
omarchy theme set tokyo-night
```

---

## Window Manager Configuration

### 11. Configure Blur Effects

Edit `~/.config/hypr/looknfeel.lua`, not the legacy `looknfeel.conf`:

```lua
hl.config({
  decoration = {
    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      ignore_opacity = true,
      noise = 0.06,
      contrast = 1.5,
      xray = false,
      new_optimizations = true,
      popups = true,
      special = true,
    },
  },
})
```

### 12. Enable Rounded Windows

In `~/.config/hypr/looknfeel.lua`:

```lua
hl.config({
  decoration = {
    rounding = 8,
  },
})
```

### 13. Configure Input Settings

In `~/.config/hypr/input.lua`, enable natural scrolling for both mouse and
touchpad, three-finger workspace gestures, and border resizing:

```lua
hl.config({
  input = {
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
```

In `~/.config/hypr/looknfeel.lua`:

```lua
hl.config({
  general = {
    resize_on_border = true,
    extend_border_grab_area = 15,
    hover_icon_on_border = true,
  },
})
```

After changing any Hyprland Lua file, validate the configuration:

```bash
hyprctl reload
hyprctl configerrors
```

### 14. Configure Omarchy Minimize (OmaVeil)

Download the Omarchy 4-compatible release. The old GitHub release uses legacy
Hyprland dispatch syntax and does not work with Omarchy 4:

```bash
curl -fL https://github.com/somtooo/OmaVeil/releases/download/2/omaveil -o /tmp/omaveil
sudo install -m 0755 /tmp/omaveil /usr/local/bin/omaveil
```

The installed binary should be at:

```
/usr/local/bin/omaveil
```

To build from the local source instead:

```bash
cd ~/devcave/OmaVeil/omaveil
cargo build --release
sudo install -m 0755 target/release/omaveil /usr/local/bin/omaveil
```

Add the keybindings to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + H", "Minimize window", "omaveil minimize")
o.bind("SUPER + I", "Browse minimized windows", "omaveil restore")
o.bind("SUPER + U", "Restore last minimized", "omaveil restore-last")
o.bind("SUPER + SHIFT + U", "Restore all minimized", "omaveil restore-all")
```

Verify the executable and bindings:

```bash
omaveil show
omarchy menu keybindings --print
```

### 15. Auto-hide the Status Bar

The bar auto-hides via the `quattrobar-autohide` Python script (repo already
cloned at `~/devcave/quattrobar-autohide`, source:
https://github.com/somtooo/quattrobar-autohide). It hides the bar when a window
overlaps it and reveals it when the cursor hits the top screen edge.

```bash
cd ~/devcave/quattrobar-autohide
make install   # installs to ~/.local/bin
```

Then autostart it from `~/.config/hypr/autostart.lua`:

```lua
o.launch_on_start("quattrobar-autohide")
```

> **With the pill bar clone (below):** use the patched copy at
> `scripts/quattrobar-autohide` in this repo — it nudges `som2.bar` (not
> `omarchy.bar`) after flag flips and accounts for the pill's extra height.

### 15b. Floating Pill Bar (som2.bar)

The status bar is a user plugin clone of `omarchy.bar` restyled as a
floating frosted-glass pill (rounded ends, 4px margins, drop shadow,
double-tap transparency preserved). Full details in
[bar-plugin.md](bar-plugin.md).

```bash
mkdir -p ~/.config/omarchy/plugins/som2.bar
cp -r bar-plugin/Bar.qml bar-plugin/BarModel.js bar-plugin/manifest.json \
      bar-plugin/widgets bar-plugin/indicators \
      ~/.config/omarchy/plugins/som2.bar/
omarchy plugin enable som2.bar
omarchy plugin disable omarchy.bar
omarchy restart shell
```

### 16. Clipboard History

Omarchy 4 includes a native clipboard manager. It records text and image
history through the running Quickshell session and stores it under
`~/.local/state/omarchy/`.

- `SUPER + V`: universal paste
- `SUPER + CTRL + V`: open the clipboard history picker
- `CTRL + SHIFT + V`: terminal paste in applications that support that shortcut

Do not add a separate `cliphist` watcher or a `SUPER + V` cliphist pipeline;
that conflicts with Omarchy's universal paste and native picker. Verify the
native watcher and history file with:

```bash
pgrep -a -f 'wl-paste.*shell/plugins/clipboard/capture.sh'
test -s ~/.local/state/omarchy/clipboard-history.json
```

---

## Login and Lock Screens

macOS-style SDDM login theme and lock screen plugin (blurred wallpaper,
circular avatar, frosted pill password field, big clock on the lock screen).
Full install/revert instructions and all theme files are in
[login-and-lock-screens.md](login-and-lock-screens.md).

Quick summary:

```bash
# SDDM login theme
pkexec bash -c 'mkdir -p /usr/share/sddm/themes/macos && cp sddm-macos-theme/* /usr/share/sddm/themes/macos/'
pkexec sed -i 's/^Current=.*/Current=macos/' /etc/sddm.conf.d/10-theme.conf

# Lock screen plugin
mkdir -p ~/.config/omarchy/plugins/som2.lock ~/.local/share/login-look
cp lock-screen-plugin/* ~/.config/omarchy/plugins/som2.lock/
cp sddm-macos-theme/avatar.png ~/.local/share/login-look/
omarchy plugin enable som2.lock
```

---

## System Services

### 17. DisplayLink Driver Setup

If using a DisplayLink dock:

1. Install evdi driver
2. Install displaylink driver
3. **Restart the PC after installation**

### 18. Enable Suspend

Omarchy 4 manages suspend availability through the system menu. Check whether
the suspend action is enabled with:

```bash
omarchy toggle enabled suspend
```

If it is disabled, toggle it with `omarchy toggle suspend`. Do not add a
separate legacy suspend or hypridle service.

### 19. Sleep, Suspend, and Hibernation

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR (Intel Core Ultra 9 285H + NVIDIA
> RTX 5070 Ti Mobile, hybrid Intel iGPU + NVIDIA dGPU, Limine UKI, encrypted
> Btrfs `/` on `/dev/mapper/root`, swapfile at `/swap/swapfile`).
>
> Goal: lid close / idle suspends in **s2idle** for a fast wake, auto-hibernates
> to disk after 35 min (zero battery drain), and **powers off cleanly**. Explicit
> `systemctl hibernate` also powers off. Resume restores the full session.

Apply all of the following.

**1. NVIDIA hibernate support.** Three things make the NVIDIA driver handle the
sleep cycle correctly:

```bash
# Shadow the packaged nvidia-sleep.conf so the driver's procfs suspend
# interface exists (same filename in /etc/modprobe.d/ replaces the packaged one).
pkexec bash -c 'cat > /etc/modprobe.d/nvidia-sleep.conf << "EOF"
options nvidia NVreg_UseKernelSuspendNotifiers=0
EOF'

# Enable the NVIDIA sleep services (drive the procfs interface around sleep).
pkexec systemctl enable nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service

# Remove nvidia from the initramfs (early KMS breaks hibernate with VRAM
# preservation). The internal panel uses the Intel iGPU, so LUKS/Plymouth are
# unaffected; nvidia loads in normal userspace a few seconds into boot.
pkexec bash -c 'mv /etc/mkinitcpio.conf.d/nvidia.conf /etc/mkinitcpio.conf.d/nvidia.conf.disabled && limine-mkinitcpio'
```

**2. Keyboard backlight off before hibernate.** The ASUS EC stalls power-off
while the keyboard backlight is on; Omarchy ships the hook but not executable.
Re-apply after Omarchy updates until fixed upstream:

```bash
pkexec chmod +x /usr/lib/systemd/system-sleep/keyboard-backlight
```

**3. Power off via shutdown, not ACPI S4.** The default `HibernateMode=platform`
asks the firmware to enter S4; on this board the dGPU won't power down, so the
machine writes the image but never turns off. `shutdown` writes the same image
then powers off via the normal kernel path:

```bash
pkexec bash -c 'mkdir -p /etc/systemd/sleep.conf.d && cat > /etc/systemd/sleep.conf.d/hibernate-mode.conf << "EOF"
[Sleep]
HibernateMode=shutdown
EOF'
```

**4. Hibernate after 35 min in suspend.** logind already prefers
suspend-then-hibernate, so lid close / idle uses it automatically — s2idle for
a quick wake, hibernate after the delay:

```bash
pkexec bash -c 'cat > /etc/systemd/sleep.conf.d/hibernate-delay.conf << "EOF"
[Sleep]
HibernateDelaySec=35min
EOF'
```

**5. Keep the default s2idle sleep state.** Do **not** add
`mem_sleep_default=deep` to the kernel cmdline — this platform advertises S3
but hangs on resume from it. The default (s2idle) is correct.

**6. Stop the lock-before-suspend service from hanging suspend.** Omarchy 4.0.2's
`omarchy-sleep-lock.service` crash-loops (holding a sleep inhibitor) when the
session is already locked, which blocks suspend indefinitely. Bound its restart
loop so it fails fast and suspend proceeds:

```bash
pkexec bash -c 'mkdir -p /etc/systemd/user/omarchy-sleep-lock.service.d && cat > /etc/systemd/user/omarchy-sleep-lock.service.d/no-crash-loop.conf << "EOF"
[Unit]
StartLimitIntervalSec=30
StartLimitBurst=10

[Service]
StartLimitAction=none
RestartSec=1
EOF'
systemctl --user daemon-reload
```

Reboot once for the cmdline and module changes to take effect.

#### Verify

```bash
cat /proc/driver/nvidia/params | grep -E "PreserveVideoMemoryAllocations|UseKernelSuspendNotifiers"
# expect: PreserveVideoMemoryAllocations: 1, UseKernelSuspendNotifiers: 0
ls /proc/driver/nvidia/suspend                                       # exists
lsinitcpio -l /boot/EFI/Linux/omarchy_linux.efi | grep -c nvidia.ko  # 0
cat /sys/power/mem_sleep          # [s2idle] deep
cat /sys/power/disk               # contains [shutdown]
systemctl is-enabled nvidia-hibernate nvidia-resume nvidia-suspend nvidia-suspend-then-hibernate
stat -c %A /usr/lib/systemd/system-sleep/keyboard-backlight           # -rwxr-xr-x

# Hibernate test (save work first): writes image, powers OFF by itself.
systemctl hibernate
# Power on -> LUKS -> SDDM login -> session restored.

# Suspend-then-hibernate test (optional): temporarily set HibernateDelaySec=3min,
# run `systemctl suspend-then-hibernate`, leave it ~3 min. It wakes itself,
# writes the image (screen stays on a few minutes — do not hard-reset), then
# powers off. Set the delay back to 35min afterward.
```

Notes:
- Use `systemctl suspend-then-hibernate` to test the timed path; plain
  `systemctl suspend` only does s2idle and never hibernates.
- Resume-from-hibernate always lands on the SDDM login (expected on an
  encrypted disk) — the session is restored after you log in.
- After many failed login/sudo attempts, PAM `pam_faillock` bans the account
  for 2 minutes and rejects even the correct password. If the lock screen or
  sudo suddenly rejects a known-good password, wait 2 minutes and retry.

### 19b. Keyboard Backlight: On While Typing, Off When Idle (ASUS)

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR. Works on any ASUS laptop
> exposing `/sys/class/leds/asus::kbd_backlight`.

ASUS laptops leave the keyboard backlight on permanently at whatever level
was last set. This installs `kbd-backlightd`, a small Python daemon (stdlib
only) that gives the Dell-style behavior: the backlight lights when you type
or touch the touchpad, and turns off after 30s of no input. It handles
suspend/resume and reboot correctly.

Behavior:

- Any keyboard or touchpad activity: backlight on, instantly, at your level.
- 30s without input: backlight off.
- Super+F2 / Super+F3 (physical Ctrl+F2/F3 with the keyd macOS map): adjust
  the level, 0-3, with the Omarchy OSD. 0 = off until you raise it again.
- The level survives sleep, hibernate, and reboot.

Note on the Fn keys: on this machine the EC handles Fn+F2/F3 (keyboard
backlight) entirely in hardware and sends nothing to Linux, so they can't be
used for control or OSD. Use Super+F2/F3 instead; the daemon re-asserts its
level on the next input event if the EC keys are pressed.

#### Install

Scripts live in [`scripts/kbd-backlight/`](scripts/kbd-backlight/):

```bash
sudo install -Dm755 scripts/kbd-backlight/kbd-backlightd /usr/local/bin/kbd-backlightd
sudo install -Dm755 scripts/kbd-backlight/kbd-backlight /usr/local/bin/kbd-backlight
sudo install -Dm644 scripts/kbd-backlight/kbd-backlightd.service /etc/systemd/system/kbd-backlightd.service
sudo systemctl daemon-reload
sudo systemctl enable --now kbd-backlightd.service
```

Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + F2", "Keyboard brightness down", "kbd-backlight down", { locked = true })
o.bind("SUPER + F3", "Keyboard brightness up", "kbd-backlight up", { locked = true })
```

#### Verify

```bash
systemctl status kbd-backlightd.service
kbd-backlight up      # level +1, OSD appears
kbd-backlight down    # level -1
# Hands off keyboard and touchpad ~35s: backlight turns off.
# Type or touch the touchpad: instantly back at your level.
```

#### Configure

Idle timeout (default 30s):

```bash
sudo systemctl edit kbd-backlightd
```

```ini
[Service]
Environment=IDLE_SECS=15
```

Then `sudo systemctl restart kbd-backlightd`.

#### Uninstall

```bash
sudo systemctl disable --now kbd-backlightd.service
sudo rm /usr/local/bin/kbd-backlightd /usr/local/bin/kbd-backlight \
        /etc/systemd/system/kbd-backlightd.service
sudo rm -rf /var/lib/kbd-backlightd
sudo systemctl daemon-reload
# and remove the SUPER+F2/F3 binds from ~/.config/hypr/bindings.lua
```

#### If the backlight dies completely (MCU wedge)

Symptom: the keyboard backlight is fully dark, the sysfs register
(`/sys/class/leds/asus::kbd_backlight/brightness`) accepts writes and reads
back the value you wrote, but the physical LEDs never light — and even the
hardware Fn+F2/F3 keys (which bypass Linux entirely) do nothing. A plain
reboot does not fix it, because the keyboard MCU (an ITE 8910 USB device)
stays powered through warm reboots. This has been observed after suspend
cycles on this machine.

Fix — USB-reset the keyboard MCU to force it to re-enumerate:

```bash
# Find the device node (usually 3-6):
for d in /sys/bus/usb/devices/*; do
  [ "$(cat $d/product 2>/dev/null)" = "ITE Device(8910)" ] && basename $d
done

# Reset it (replace 3-6 with the node found above):
echo "3-6" | sudo tee /sys/bus/usb/drivers/usb/unbind
sleep 2
echo "3-6" | sudo tee /sys/bus/usb/drivers/usb/bind

# Backlight should respond again:
echo 3 | sudo tee /sys/class/leds/asus::kbd_backlight/brightness
```

If the USB reset does not bring it back: full shutdown (not reboot), wait
10s, power on. Last resort: shutdown, unplug the charger, hold the power
button 30s to drain residual power and cold-boot the EC.

### 20. Setup Btrfs Snapshots

Omarchy creates Snapper snapshots for system updates. These are separate from
Pika Backup and can be used for system rollback. Check the existing snapshots
with:

```bash
sudo snapper -c root list
```

For regular timeline snapshots, configure the `root` profile in
**Btrfs Assistant** and enable the Snapper timers:

```bash
sudo snapper -c root set-config \
  TIMELINE_CREATE=yes \
  TIMELINE_LIMIT_HOURLY=2 \
  TIMELINE_LIMIT_DAILY=2 \
  TIMELINE_LIMIT_WEEKLY=0 \
  TIMELINE_LIMIT_MONTHLY=0 \
  TIMELINE_LIMIT_YEARLY=0
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

`snapper-timeline.timer` creates the snapshots. The cleanup timer only removes
old snapshots; enabling cleanup alone does not create them. Keep Omarchy's
number-snapshot retention setting when changing timeline retention so update
rollback snapshots are not removed prematurely.

![Btrfs Snapshot Configuration](btrfs-assistant.png)
---

## Backup Configuration

### 21. Mount Google Drive with rclone

#### Prerequisites

- Install rclone: `pacman -S rclone`
- Configure Google Drive remote: `rclone config` -  [rclone-gdrive](https://rclone.org/drive/)

#### Setup

**Create mount directory:**

```bash
sudo mkdir -p /media/gdrive
sudo chown $USER:$USER /media/gdrive
```

**Create systemd user service:**

Create `~/.config/systemd/user/rclone-gdrive.service`:

```ini
[Unit]
Description=Mount Google Drive with rclone
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount g-drive: /media/gdrive --vfs-cache-mode full
ExecStop=/usr/bin/fusermount3 -u /media/gdrive
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

**Enable and start the service:**

```bash
systemctl --user daemon-reload
systemctl --user enable --now rclone-gdrive.service
```

#### Usage

Check status:

```bash
systemctl --user status rclone-gdrive.service
```

Manual control:

```bash
systemctl --user stop rclone-gdrive.service
systemctl --user start rclone-gdrive.service
```

#### Notes

- Using `/media` ensures Nautilus displays the mount with a drive icon in the sidebar
- `--vfs-cache-mode full` enables full file caching, required for apps like Pika Backup
- The service auto-starts on login and restarts on failure

### 22. Configure Pika Backup

1. Install **Pika Backup**
2. Configure backup destination to `/media/gdrive`
3. Set backup schedule:
   - **Hourly**: 1 backup
   - **Daily**: 3 backups
   - **Weekly**: 1 backup
4. Enable "Regularly create backups"

---

## Development Tools

### 23. Install Zed Editor

1. Install Zed from their official website (not from AUR)
2. Add the binary installation location to PATH if not already added
3. Verify `zed` CLI command works

---

## Audio Configuration

### 24. Use the Omarchy 4 Audio OSD

Omarchy 4 replaced SwayOSD with a Quickshell-based OSD. Do not install or
configure `swayosd`; the old `max_volume = 150` setting is not supported by
the native volume command.

Use the native audio commands instead:

```bash
omarchy audio output volume raise
omarchy audio output volume lower
omarchy audio output volume mute-toggle
omarchy audio output volume +1
omarchy audio output volume -1
```

The volume keys and audio panel use the same commands and show the native
Omarchy OSD automatically.

## Additional Resources

- [Hyprland Documentation](https://wiki.hyprland.org/)
- [rclone Documentation](https://rclone.org/)

---
