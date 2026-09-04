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
8. [System Services](#system-services) — includes macOS-style safe sleep (19)
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

### 19. Fix NVIDIA Hibernation Resume

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR (Intel Core Ultra 9 285H + NVIDIA RTX 5070 Ti Mobile (GB205M), 32 GiB RAM, hybrid Intel iGPU + NVIDIA dGPU, Limine UKI, encrypted Btrfs `/` on `/dev/mapper/root` with `/swap/swapfile`).
> **Note:** Earlier drafts of this section (a) added `suspend-then-hibernate`/lid drop-ins and (b) edited package-owned files in `/usr/lib/modprobe.d/`. All **reverted 2026-09-03** — the final fix below changes only `/etc/mkinitcpio.conf.d/`, survives package updates, and keeps Omarchy 4 defaults otherwise untouched.

#### 19.1 What broke (2026-09-01 — 2026-09-03)

Hibernation entered cleanly (`journalctl -b -1`):

```
systemd-logind[999]: hibernate requested from client ... ('systemctl')
systemd-sleep[268539]: Performing sleep operation 'hibernate'...
kernel: PM: hibernation: hibernation entry
```

On next boot the image was found, fully loaded, then discarded (`journalctl -b 0 -k`):

```
kernel: PM: Image signature found, resuming
kernel: PM: hibernation: resume from hibernation
kernel: PM: Loading and decompressing image data (2341251 pages)...
kernel: PM: Image loading progress: 100%
kernel: PM: Image successfully loaded
kernel: NVRM: GPU 0000:01:00.0: PreserveVideoMemoryAllocations module parameter is set. System Power Management attempted without driver procfs suspend interface.
kernel: nvidia 0000:01:00.0: PM: pci_pm_freeze(): nv_pmops_freeze [nvidia] returns -5
kernel: nvidia 0000:01:00.0: PM: dpm_run_callback(): pci_pm_freeze returns -5
kernel: nvidia 0000:01:00.0: PM: failed to quiesce async: error -5
kernel: PM: hibernation: Failed to load image, recovering.
kernel: PM: hibernation: resume failed (-5)
```

The machine then booted normally (looks like a plain shutdown).

#### 19.2 Root cause (confirmed in 610.57.04 source + NVIDIA README)

Chain of failure:

1. `gpu-screen-recorder` ships `/usr/lib/modprobe.d/gsr-nvidia.conf` with `options nvidia NVreg_PreserveVideoMemoryAllocations=1`.
2. Omarchy early-loads the nvidia modules via `/etc/mkinitcpio.conf.d/nvidia.conf` (`MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)`) — **early KMS**.
3. In the open kernel module (`nvidia-open-dkms` 610.57.04), `nvidia_suspend()` rejects any PM action with `NV_ERR_NOT_SUPPORTED` when `preserve_vidmem_allocations && !is_procfs_suspend`, and `nv_pmops_freeze()` hardcodes `is_procfs_suspend=NV_FALSE` (`kernel-open/nvidia/nv.c`). So hibernate entry writes the image, but on the next boot the fresh nvidia driver in the initramfs refuses to quiesce → `pci_pm_freeze` returns `-5` (`EIO`) → the kernel discards the loaded image and recovers into a normal boot.
4. The `nvidia-sleep.sh` / `/proc/driver/nvidia/suspend` path (the documented fix for the proprietary driver) cannot help here: `/usr/lib/modprobe.d/nvidia-sleep.conf` sets `NVreg_UseKernelSuspendNotifiers=1`, and with that the open module does not even create `/proc/driver/nvidia/suspend` (`nv-procfs.c`: `if (NVreg_UseKernelSuspendNotifiers) create_suspend_file = NV_FALSE`). Enabling `nvidia-{suspend,hibernate,resume}.service` is therefore a no-op on this driver. (Verified: with services enabled, hibernate still failed identically at `19:57→19:59`, and `ls /proc/driver/nvidia/suspend` → no such file.)
5. Per NVIDIA README 610.57.04: with open kernel modules, preservation "is handled automatically if `NVreg_UseKernelSuspendNotifiers=1` is enabled" — **but** ArchWiki adds the critical caveat: with early KMS the module loads in the initramfs, which "has no access to `NVreg_TemporaryFilePath` which stores the previous video memory: early KMS should not be used if hibernation is desired." The initramfs also lacks writable `/var/tmp`, so the automatic path cannot function either.

`resume=/dev/mapper/root resume_offset=3735407` (`/proc/cmdline`, `/etc/limine-entry-tool.d/resume.conf`) matches `/sys/power/resume`/`resume_offset`, and the 30.8G `/swap/swapfile` (`swapon --show`, `/etc/fstab`) is correctly sized — swap layout was never the problem. Verified with `omarchy hibernation available` (swap > `/sys/power/image_size`).

#### 19.3 Fix applied (2026-09-03) — disable nvidia early KMS

The fix keeps the stock parameters (`PreserveVideoMemoryAllocations=1`, `UseKernelSuspendNotifiers=1`, `TemporaryFilePath=/var/tmp`) and removes nvidia from the initramfs so the module loads in real userspace where `/var/tmp` exists and the notifier path works:

```bash
pkexec bash -c '
  # mkinitcpio only reads *.conf in this dir, so renaming disables it
  mv /etc/mkinitcpio.conf.d/nvidia.conf /etc/mkinitcpio.conf.d/nvidia.conf.disabled
  limine-mkinitcpio
'
```

Also reverted two earlier wrong turns:

```bash
# services are a no-op with the open module (no procfs file) — back to Arch default (disabled)
pkexec systemctl disable nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service
# package-owned modprobe files restored to stock values
#   /usr/lib/modprobe.d/gsr-nvidia.conf:   NVreg_PreserveVideoMemoryAllocations=1
#   /usr/lib/modprobe.d/nvidia-sleep.conf: NVreg_UseKernelSuspendNotifiers=1
```

Tradeoffs:

- The graphical (Plymouth) boot splash may fall back to a text/lower-res mode until nvidia loads after root mount; on this hybrid laptop the panel is driven by the Intel iGPU (`i915`, kept via the `kms` hook), so early boot display still works.
- If early nvidia KMS is ever needed again (e.g. Wayland session fully on the dGPU), restore with `pkexec mv /etc/mkinitcpio.conf.d/nvidia.conf.disabled /etc/mkinitcpio.conf.d/nvidia.conf && pkexec limine-mkinitcpio` — but hibernation will break again.

Everything else stays at Omarchy defaults: no `sleep.conf.d`/`logind.conf.d` additions (only Omarchy-shipped `10-ignore-power-button.conf`, `20-inhibit-delay.conf`), `resume=` params from `omarchy-hibernation-setup`, and `/usr/lib/systemd/system-sleep/{nvidia,keyboard-backlight,unmount-fuse}` hooks unchanged.

#### 19.4 Verify after reboot

```bash
# 1) nvidia no longer in initramfs (module loads after root mount)
lsinitcpio -l /boot/EFI/Linux/omarchy_linux.efi | grep -c "nvidia.ko"   # expect 0 modules

# 2) stock params active
cat /proc/driver/nvidia/params | grep -E "PreserveVideoMemoryAllocations|UseKernelSuspendNotifiers"
# PreserveVideoMemoryAllocations: 1  /  UseKernelSuspendNotifiers: 1

# 3) hibernate test (save work first — writes RAM to /swap/swapfile, powers off)
systemctl hibernate
# on next boot:
journalctl -b 0 -k | grep -E "PM: hibernation|nvidia.*PM:"
# want: "PM: hibernation: resume from hibernation", no "resume failed (-5)"
journalctl -b -1 | grep -E "hibernation entry"

# 4) full revert
pkexec bash -c 'mv /etc/mkinitcpio.conf.d/nvidia.conf.disabled /etc/mkinitcpio.conf.d/nvidia.conf; limine-mkinitcpio'
```

Rebuild UKI after any mkinitcpio/resume change: `pkexec limine-mkinitcpio`.

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
