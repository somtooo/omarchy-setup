# Omarchy System Setup Guide

A comprehensive guide for setting up and configuring Omarchy Linux distribution.

---

## Table of Contents

1. [Initial Software Installation](#initial-software-installation)
2. [Keyboard Configuration](#keyboard-configuration)
3. [Restore Configurations](#restore-configurations)
4. [Hy
prland Display Management](#hyprland-display-management)
5. [UI Customization](#ui-customization)
6. [Window Manager Configuration](#window-manager-configuration)
7. [System Services](#system-services)
8. [Backup Configuration](#backup-configuration)
9. [Development Tools](#development-tools)
10. [Audio Configuration](#audio-configuration)

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

### 5. Configure Lid Close Behavior

Automatically disable the laptop's built-in display (eDP-1) when the lid is closed and an external monitor is connected.

#### Problem

Hyprland's `bindl` for lid switch events doesn't work reliably on resume from suspend. The hardware event fires before Hyprland is fully awake.

#### Solution

Use hypridle's `after_sleep_cmd` which triggers via dbus after the system fully resumes.

#### Step 1: Create the lid switch script

Create `~/.config/hypr/scripts/lid.sh`:

```bash
#!/bin/bash

case "$1" in
    close)
        # Only disable eDP-1 if external monitor is connected
        if hyprctl monitors -j | jq -e '[.[] | select(.name != "eDP-1")] | length > 0' > /dev/null; then
            hyprctl keyword monitor "eDP-1, disable"
        fi
        ;;
    open)
        # Re-enable eDP-1
        hyprctl keyword monitor "eDP-1, preferred, auto, 1"
        ;;
esac
```

Make it executable:

```bash
chmod +x ~/.config/hypr/scripts/lid.sh
```

#### Step 2: Add lid switch bindings to Hyprland

Add to `~/.config/hypr/bindings.conf`:

```conf
# Lid switch - disable laptop monitor when closed with external display
bindl = , switch:on:Lid Switch, exec, ~/.config/hypr/scripts/lid.sh close
bindl = , switch:off:Lid Switch, exec, ~/.config/hypr/scripts/lid.sh open
```

This handles lid events when NOT suspending.

#### Step 3: Configure hypridle for suspend/resume

Add or modify the `after_sleep_cmd` in `~/.config/hypr/hypridle.conf`:

```conf
general {
    after_sleep_cmd = hyprctl dispatch dpms on && ~/.config/hypr/scripts/lid.sh open
}
```

This ensures eDP-1 is re-enabled after waking from suspend.

#### Step 4: Restart hypridle

```bash
pkill hypridle && hypridle &
disown
```

#### Notes

- Replace `eDP-1` with your laptop display name (check with `hyprctl monitors`)
- The script requires `jq` to be installed: `sudo pacman -S jq`
- Logs can be added to the script for debugging by echoing to `/tmp/lid-switch.log`

---

## UI Customization

### 6. Setup Waybar Autohide

Install waybar-autohide-enhanced from: https://github.com/somtooo/waybar-autohide-enhanced

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

### 10. Configure GTK Theme Settings

Install and use nwg-look:

- Set default font to **Inter**
- Enable all antialiasing options
- Set icon theme to **Colloid**

---

## Window Manager Configuration

### 11. Configure Blur Effects

Add blur settings to `looknfeel.conf`. Choose one of the following configurations:

#### Option 1: Balanced Blur

```conf
blur {
    enabled = true
    size = 10
    passes = 3
    noise = 0.02
    contrast = 1.0
    brightness = 0.7
    vibrancy = 0.2
    vibrancy_darkness = 0.5
    popups = true
    special = true
}
```

#### Option 2: Performance Optimized

```conf
blur {
    enabled = true
    size = 7
    passes = 3
    ignore_opacity = true
    noise = 0.06
    contrast = 1.5
    xray = false
    new_optimizations = true
    popups = true
    special = true
}
```

### 12. Enable Rounded Windows

In `looknfeel.conf`, uncomment the rounded windows configuration.

### 13. Configure Input Settings

In `input.conf`:

1. Uncomment the three-finger swipe to change workspace setting
2. Add window resize configuration:
3. Uncomment natural scrolling and duplicate it in the input block so it works for bluetooth mouse

```conf
# Enable window resize by dragging edges (like macOS/Windows)
general {
  resize_on_border = true
  extend_border_grab_area = 15  # pixels to grab from edge
  hover_icon_on_border = true   # show resize cursor
}
```

### 14. Add Omarchy Minimize (OmaVeil)

Install the OmaVeil binary from GitHub Releases and place it in `/usr/local/bin` so Hyprland can find it:

```
/usr/local/bin/omaveil
```

Add the keybindings to `~/.config/hypr/bindings.conf`:

```conf
# OmaVeil - window minimizer (omarchy-native minimize using Walker)
bindd = SUPER, H, Minimize window, exec, omaveil minimize
bindd = SUPER, I, Browse minimized windows, exec, omaveil restore
bindd = SUPER, U, Restore last minimized, exec, omaveil restore-last
bindd = SUPER SHIFT, U, Restore all minimized, exec, omaveil restore-all
```

---

## System Services

### 14. DisplayLink Driver Setup

If using a DisplayLink dock:

1. Install evdi driver
2. Install displaylink driver
3. **Restart the PC after installation**

### 15. Enable Suspend

Enable system suspend feature by following the instructions in the Omarchy setup guide.

### 16. Setup Btrfs Snapshots

1. Install **btrfs-assistant**
2. Configure cron snapshots for root partition
3. Recommended schedule: Regular automated snapshots

![Btrfs Snapshot Configuration](btrfs-assistant.png)
---

## Backup Configuration

### 17. Mount Google Drive with rclone

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
Type=simple
ExecStart=/usr/bin/rclone mount g-drive: /media/gdrive --vfs-cache-mode full
ExecStop=/bin/fusermount -u /media/gdrive
Restart=on-failure

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

### 18. Configure Pika Backup

1. Install **Pika Backup**
2. Configure backup destination to `/media/gdrive`
3. Set backup schedule:
   - **Hourly**: 1 backup
   - **Daily**: 3 backups
   - **Weekly**: 1 backup
4. Enable "Regularly create backups"

---

## Development Tools

### 19. Install Zed Editor

1. Install Zed from their official website (not from AUR)
2. Add the binary installation location to PATH if not already added
3. Verify `zed` CLI command works

---

## Audio Configuration

### 20. Fix Maximum Volume (SwayOSD)

If volume is limited to 100% and sounds too quiet confirm omarchy still uses SwayOSD then:

#### Solution

Create user config at `~/.config/swayosd/config.toml`:

```toml
[server]
max_volume = 150

[client]
```

Restart the server:

```bash
pkill swayosd-server && swayosd-server &
```

#### Config Locations

- **System default**: `/etc/xdg/swayosd/config.toml`
- **User override**: `~/.config/swayosd/config.toml`

#### Other Useful Options

```toml
[server]
max_volume = 150
min_brightness = 5
# style = /path/to/custom/style.css
# top_margin = 0.85
# show_percentage = true
```

## Additional Resources

- [Hyprland Documentation](https://wiki.hyprland.org/)
- [rclone Documentation](https://rclone.org/)
- [Waybar Documentation](https://github.com/Alexays/Waybar)

---
