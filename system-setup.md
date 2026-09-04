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

### 19. Fix NVIDIA Hibernation

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR (Intel Core Ultra 9 285H + NVIDIA RTX 5070 Ti Mobile (GB205M), 32 GiB RAM, hybrid Intel iGPU + NVIDIA dGPU, Limine UKI, encrypted Btrfs `/` on `/dev/mapper/root` with `/swap/swapfile`).
> **Tested 2026-09-03:** hibernate writes image, keyboard backlight turns off, machine powers off, resume restores full session.

#### 19.1 Symptom

`systemctl hibernate` enters hibernation (`PM: hibernation: hibernation entry`), but on next boot the image is loaded and then discarded — machine behaves like a fresh boot:

```
kernel: PM: hibernation: resume from hibernation
kernel: PM: Image loading progress: 100%
kernel: PM: Image successfully loaded
kernel: NVRM: GPU 0000:01:00.0: PreserveVideoMemoryAllocations module parameter is set. System Power Management attempted without driver procfs suspend interface.
kernel: nvidia 0000:01:00.0: PM: pci_pm_freeze(): nv_pmops_freeze [nvidia] returns -5
kernel: PM: hibernation: Failed to load image, recovering.
kernel: PM: hibernation: resume failed (-5)
```

After fixing that, a second symptom: hibernate entry hangs with a black screen and the keyboard backlight stuck on, requiring a hard power-off.

#### 19.2 Root causes

**A. NVIDIA driver refuses to quiesce.** `gpu-screen-recorder` ships `/usr/lib/modprobe.d/gsr-nvidia.conf` with `NVreg_PreserveVideoMemoryAllocations=1`. In `nvidia-open` 610.57.04, `nvidia_suspend()` refuses PM entry when preservation is on but the procfs suspend interface was not used. Two things conspire to make the procfs path unavailable:

- `/usr/lib/modprobe.d/nvidia-sleep.conf` sets `NVreg_UseKernelSuspendNotifiers=1`, and with that the driver does not create `/proc/driver/nvidia/suspend` (`nv-procfs.c`: `if (NVreg_UseKernelSuspendNotifiers) create_suspend_file = NV_FALSE`).
- The `nvidia-{suspend,hibernate,resume}.service` units (which drive the procfs interface via `nvidia-sleep.sh`) are disabled by default on 595+.

**B. ASUS keyboard EC blocks S4 while the backlight is on.** Omarchy ships a sleep hook for this (`/usr/lib/systemd/system-sleep/keyboard-backlight`), but the shipped file is not executable (`-rw-r--r--`), so systemd-sleep silently skips it. Hibernation then stalls at the EC for ~15 minutes with the backlight lit.

#### 19.3 Fix

**1. Disable kernel suspend notifiers so the procfs interface exists.** Use an `/etc/modprobe.d/` drop-in (survives package updates; do not edit the package files in `/usr/lib/modprobe.d/`):

```bash
pkexec bash -c 'cat > /etc/modprobe.d/nvidia-hibernate.conf << "EOF"
# Create /proc/driver/nvidia/suspend so nvidia-sleep.sh can drive VRAM
# preservation. Required for hibernate with NVreg_PreserveVideoMemoryAllocations=1
# (set by gpu-screen-recorder'''s /usr/lib/modprobe.d/gsr-nvidia.conf).
options nvidia NVreg_UseKernelSuspendNotifiers=0
EOF'
```

**2. Enable the NVIDIA sleep services** so `nvidia-sleep.sh` writes `hibernate`/`resume` to the procfs interface around the sleep cycle:

```bash
pkexec systemctl enable nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service
```

**3. Remove nvidia from the initramfs (early KMS).** Omarchy early-loads the modules via `/etc/mkinitcpio.conf.d/nvidia.conf`; with early KMS the initramfs has no access to `NVreg_TemporaryFilePath` (`/var/tmp`), which the preservation feature needs. `mkinitcpio` only reads `*.conf` in that directory, so rename it and rebuild the UKI:

```bash
pkexec bash -c '
  mv /etc/mkinitcpio.conf.d/nvidia.conf /etc/mkinitcpio.conf.d/nvidia.conf.disabled
  limine-mkinitcpio
'
```

The internal panel is driven by the Intel iGPU (`i915`, still in the initramfs via the `kms` hook), so the LUKS prompt and Plymouth splash are unaffected; nvidia loads in normal userspace a few seconds later. Only visible tradeoff: an external monitor on the dGPU-wired HDMI port stays dark until the module loads.

**4. Make the keyboard backlight sleep hook executable** (upstream Omarchy ships it `-rw-r--r--`; re-apply after Omarchy updates until fixed upstream):

```bash
pkexec chmod +x /usr/lib/systemd/system-sleep/keyboard-backlight
```

No systemd `sleep.conf.d`/`logind.conf.d` additions; lid/idle behavior stays at Omarchy defaults. The `resume=`/`resume_offset=` kernel parameters and `/swap/swapfile` from `omarchy-hibernation-setup` are used unchanged.

#### 19.4 Verify (after reboot)

```bash
# params and procfs interface
cat /proc/driver/nvidia/params | grep -E "PreserveVideoMemoryAllocations|UseKernelSuspendNotifiers"
# expect: PreserveVideoMemoryAllocations: 1, UseKernelSuspendNotifiers: 0
ls /proc/driver/nvidia/suspend          # expect: exists
lsinitcpio -l /boot/EFI/Linux/omarchy_linux.efi | grep -c "nvidia.ko"   # expect: 0

# services + hook
systemctl is-enabled nvidia-hibernate nvidia-resume nvidia-suspend nvidia-suspend-then-hibernate
stat -c %A /usr/lib/systemd/system-sleep/keyboard-backlight             # expect: -rwxr-xr-x

# hibernate test (save work first)
systemctl hibernate
# expect: backlight off, power off within ~30s; on power-on: LUKS prompt, then session restored
journalctl -b 0 -k | grep -E "PM: hibernation|nvidia.*PM:"
# expect: "resume from hibernation" with no "returns -5"
```

#### 19.5 Revert

```bash
pkexec systemctl disable nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service
pkexec rm /etc/modprobe.d/nvidia-hibernate.conf
pkexec bash -c 'mv /etc/mkinitcpio.conf.d/nvidia.conf.disabled /etc/mkinitcpio.conf.d/nvidia.conf; limine-mkinitcpio'
```

### 19b. Dell-style Keyboard Backlight Idle-Off (ASUS)

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR, but works on any ASUS laptop
> exposing `/sys/class/leds/asus::kbd_backlight`.
> **Tested 2026-09-04:** backlight lights on keypress or touchpad touch at the
> last Fn-set level, turns off after 30s idle, Fn+F3 down to 0 stays off.

Unlike Dell laptops (whose EC turns the keyboard backlight on while typing and
fades it out when idle), ASUS exposes only a raw brightness level
(`asus::kbd_backlight`, levels 0-3) to Linux. asusctl v6 removed its old
`awake` LED mode, so out of the box the backlight just stays on at whatever
level Fn+F3/F4 set. This section installs a small dependency-free daemon that
recreates the Dell behavior in userspace.

Behavior:

- Pressing any key **or touching the touchpad** lights the backlight at the
  level last set with Fn+F3/F4.
- After **30 seconds** with no keyboard or touchpad activity, the backlight
  turns off.
- Fn+F3/F4 still control the brightness level (handled by Omarchy's
  `omarchy-brightness-keyboard` binding); pressing Fn+F3 down to 0 turns the
  light off and it stays off until Fn+F4 is pressed.

How it works: the daemon reads raw `input_event`s from the keyboard and
touchpad devices with `dd` (no evtest/libinput dependency). Because **keyd**
grabs the physical keyboard, the daemon watches the `keyd virtual keyboard`
device instead; the touchpad is not grabbed by keyd and is read directly.
The level is persisted in `/run/kbd-idle-level` (brightnessctl cannot be used
here — it hangs on D-Bus when run as root).

#### Install

Scripts live in [`scripts/kbd-backlight-idle/`](scripts/kbd-backlight-idle/):

```bash
sudo install -Dm755 scripts/kbd-backlight-idle/kbd-idle-daemon /usr/local/bin/kbd-idle-daemon
sudo install -Dm644 scripts/kbd-backlight-idle/kbd-idle-daemon.service /etc/systemd/system/kbd-idle-daemon.service
sudo systemctl daemon-reload
sudo systemctl enable --now kbd-idle-daemon.service
```

#### Verify

```bash
systemctl status kbd-idle-daemon.service
journalctl -u kbd-idle-daemon -f   # should show the watched keyboard + touchpad devices

# Hands off keyboard and touchpad for ~35s:
watch -n1 cat /sys/class/leds/asus::kbd_backlight/brightness   # drops to 0
# Type a key or touch the touchpad: returns to previous level
```

#### Configure

Change the idle timeout (default 30s) with a drop-in:

```bash
sudo systemctl edit kbd-idle-daemon
```

```ini
[Service]
Environment=IDLE_SECS=15
```

Then `sudo systemctl restart kbd-idle-daemon`.

#### Uninstall

```bash
sudo systemctl disable --now kbd-idle-daemon.service
sudo rm /usr/local/bin/kbd-idle-daemon /etc/systemd/system/kbd-idle-daemon.service
sudo systemctl daemon-reload
```

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
