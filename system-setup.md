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
hardware and sends nothing to Linux — see [19b](#19b-dell-style-keyboard-backlight-idle-off-asus).

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

**1. Disable kernel suspend notifiers so the procfs interface exists.** This must be a **same-named shadow** of the packaged `/usr/lib/modprobe.d/nvidia-sleep.conf` — per modprobe.d(5), a file in `/etc/modprobe.d/` with the *same filename* completely replaces the packaged one. A *differently*-named drop-in (e.g. `nvidia-hibernate.conf`) does NOT work: both files load in lexicographic order and the packaged `=1` wins because it sorts later. (Regression seen 2026-09-04: suspend froze mid-entry after a package refresh re-asserted the packaged default.)

```bash
pkexec bash -c 'cat > /etc/modprobe.d/nvidia-sleep.conf << "EOF"
# Shadow of /usr/lib/modprobe.d/nvidia-sleep.conf. The packaged file sets
# NVreg_UseKernelSuspendNotifiers=1, which suppresses /proc/driver/nvidia/suspend
# and breaks suspend/hibernate here (nv_pmops_freeze -> -5).
options nvidia NVreg_UseKernelSuspendNotifiers=0
EOF'
```

Verify with `modprobe -c | grep UseKernelSuspendNotifiers` — every line must say `=0`. Requires a reboot to apply to the loaded module.

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

Lid/idle behavior stays at Omarchy defaults. The `resume=`/`resume_offset=` kernel parameters and `/swap/swapfile` from `omarchy-hibernation-setup` are used unchanged.

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
pkexec rm /etc/modprobe.d/nvidia-sleep.conf
pkexec bash -c 'mv /etc/mkinitcpio.conf.d/nvidia.conf.disabled /etc/mkinitcpio.conf.d/nvidia.conf; limine-mkinitcpio'
```

#### 19.6 Suspend regression: `mem_sleep_default=deep` freezes on resume (do not use)

> **Regression 2026-09-04, fixed same day.** Plain `systemctl suspend` / lid-close
> suspended but **froze on resume** (backlight flicker, then a hang requiring a
> hard power-off). Hibernate (§19.1–19.5) was unaffected — this is a separate
> change that broke S3, not the hibernate fix.

**Symptom.** Suspend enters (`PM: suspend entry (deep)`) but the journal never
logs `suspend exit`; the next boot is a clean power-on (`PM: Image not found`,
since no hibernate image was written). Journal evidence: `deep` was entered
twice and resumed **0/2** times, while `s2idle` resumed **36/36**.

**Root cause.** A prior session appended `mem_sleep_default=deep` to
`/etc/default/limine` to reduce battery drain (s2idle drains the battery within
a day). That flips suspend from **s2idle** to **S3/"deep"**. This machine (Intel
Core Ultra 9 285H, a modern-standby / S0ix platform) advertises `S3` in ACPI but
cannot actually resume from it — the S3 resume path hangs. Because the kernel
cmdline is baked into the UKI, the change only took effect after the next reboot,
which is why suspend "suddenly" broke in the morning.

**Fix — keep s2idle (revert the `deep` override).** Remove the line and rebuild
the UKI:

```bash
pkexec sed -i '/mem_sleep_default=deep/d' /etc/default/limine
pkexec limine-mkinitcpio   # regenerates /boot/limine.conf + the UKI
```

Verify after reboot: `cat /sys/power/mem_sleep` → `s2idle [deep]` becomes
`[s2idle] deep` (s2idle selected). Do **not** re-add `mem_sleep_default=deep` —
it is unrecoverable on this hardware.

**Battery drain is handled without deep sleep.** With s2idle restored, logind
already prefers **suspend-then-hibernate** (`SleepOperation` defaults to
`suspend-then-hibernate suspend`, and `CanSuspendThenHibernate` reports `yes`
here). So a lid close suspends in
s2idle for a quick wake, then automatically hibernates after
`HibernateDelaySec` (compiled default **2h**) — zero battery drain on long
sleeps, reliable resume on short ones. No `sleep.conf.d` override is needed;
the defaults are correct. (To shorten the 2h delay, an optional drop-in is
`Sleep.HibernateDelaySec=` in `/etc/systemd/sleep.conf.d/` — not required.)

**Key distinction:** hibernate uses **S4**, suspend-then-hibernate's suspend
phase uses the default sleep state (now s2idle again). The broken `deep` path
only ever affected the suspend phase.

**Testing note.** To verify suspend-then-hibernate, set a short delay:

```bash
pkexec bash -c 'mkdir -p /etc/systemd/sleep.conf.d && cat > /etc/systemd/sleep.conf.d/hibernate-delay.conf << "EOF"
[Sleep]
HibernateDelaySec=3min
EOF'
```

Then run `systemctl suspend-then-hibernate` (NOT `systemctl suspend` — that verb
is hardcoded to plain suspend and bypasses the logind preference). Expect:
sleep in a few seconds, self-wake at 3 min, ~4 min writing the image with the
screen on (this looks stuck but is not — do not hard-reset), then power off.
Resume shows the SDDM login (normal for encrypted hibernate). Raise or remove
the drop-in once confirmed.

#### 19.8 Hibernate writes the image but never powers off (fans/backlight stay on)

> **Regression found 2026-09-04, fixed same day.** `systemctl hibernate` (and the
> hibernate phase of suspend-then-hibernate) wrote the image — sessions restored
> on next boot — but the laptop **stayed powered on** (fans spinning, sometimes
> the backlight on) and had to be hard-powered-down. The journal shows the S4
> power-off **aborting**:
>
> ```
> ACPI: PM: Preparing to enter system sleep state S4
> ACPI: PM: Waking up from system sleep state S4      ← bounces back immediately
> PM: hibernation: hibernation exit                   ← aborts instead of cutting power
> NVRM: gpuGc6EntryGpuPowerOff_IMPL: Call to power off GPU failed.
> ```

**Root cause.** `HibernateMode` defaults to `platform`, which asks the ACPI
firmware to enter S4 and cut power. On this modern-standby (S0ix) board the
NVIDIA dGPU refuses to enter its GC6 power-off state, so the platform S4
transition aborts and the kernel "wakes" back out of S4 instead of powering
down. The image is already safely on disk, so resume still works — but the
machine never actually turns off.

**Fix.** Use the `shutdown` hibernate mode: write the same resumable image, then
power off via the normal kernel shutdown path instead of asking ACPI for S4:

```bash
pkexec bash -c 'cat > /etc/systemd/sleep.conf.d/hibernate-mode.conf << "EOF"
[Sleep]
HibernateMode=shutdown
EOF'
```

Resume is identical (LUKS → SDDM → session restored). Verified 2026-09-04: the
machine powers off by itself. To test before making it permanent, set the live
value with `pkexec sh -c "echo shutdown > /sys/power/disk"`, confirm
`cat /sys/power/disk` shows `[shutdown]`, then `systemctl hibernate`.

#### 19.9 Sudo / lock-screen password "not working" — faillock temporary ban

Not a hibernate problem, but it surfaced during this debugging: after many
failed unlock/sudo attempts (hard-reset loops, retrying the lock screen while
suspend was broken), PAM's `pam_faillock` (`deny=10 unlock_time=120` in
`/etc/pam.d/system-auth` and `/etc/pam.d/omarchy-lock-password`) **bans the
account for 120 s**. During the ban the *correct* password is rejected
everywhere — sudo and the lock screen alike. It clears on its own after 2 min
(`faillock --user $USER` shows the counter). If your password "stops working"
during heavy testing, wait 2 minutes and retry before assuming it's wrong.

#### 19.7 Suspend hangs when the screen is already locked (Omarchy lock-service crash loop)

> **Regression 2026-09-04, fixed same day.** A *second* `suspend-then-hibernate`
> hung with the screen on, never reached `suspend entry`, requiring a hard
> reset. The **first** suspend worked. Unrelated to nvidia, sleep state, or
> hibernate — the journal never left userspace.

**Root cause.** Upstream Omarchy 4.0.2 bug. `omarchy-sleep-lock.service`
(lock-screen-before-suspend monitor) runs a persistent
`systemd-inhibit --what=sleep --mode=delay` lock as its main process. When the
session is **already locked** (e.g. the idle timer locked it before suspend
fired — exactly what the 3-minute test invites), a fresh inhibit fails with
`Failed to inhibit: The operation inhibition has been requested for is already
running`, the service exits 1, and the unit's `Restart=always` +
`StartLimitAction=none` restart it **forever** (35+ restarts in ~48 s observed).
Each attempt holds a sleep delay-inhibitor, so `systemd-suspend` waits on it
indefinitely → the machine sits powered-on, never sleeping. Suspending unlocked
is the designed fallback (the lock script reports it); the infinite hang is the
bug.

**Fix.** A drop-in that bounds the restart loop so the service fails fast and
suspend proceeds, instead of hanging the machine:

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

With this, if the lock cannot be acquired the unit gives up after ~10 s and
suspend continues (unlocked), rather than the machine hanging. This is a
workaround for an upstream defect; re-check after Omarchy updates.

### 19b. Dell-style Keyboard Backlight Idle-Off (ASUS)

> **Hardware:** ASUS ROG Zephyrus G16 GU605CR, but works on any ASUS laptop
> exposing `/sys/class/leds/asus::kbd_backlight`.
> **Tested 2026-09-04:** instant relight on keypress/touchpad, idle-off after
> 30s, level survives suspend/resume and reboot, Super+F2/F3 adjust with the
> Omarchy OSD.

Unlike Dell laptops (whose EC turns the keyboard backlight on while typing
and fades it out when idle), ASUS exposes only a raw brightness level
(`asus::kbd_backlight`, levels 0-3) to Linux, and asusctl v6 removed its old
`awake` LED mode. This section installs `kbd-backlightd`, a tiny Python
daemon that recreates the Dell behavior.

#### Design

One process, one thread, one selector event loop. All state lives in memory
inside that loop, so races are impossible by construction — every event
(input, command, timer) is processed atomically, one at a time. (Earlier
shell-script versions of this feature kept state in files shared between a
handful of concurrent processes; every bug they had was the same race in a
new costume.)

The daemon maintains a single invariant:

```
LED = L   if L > 0 and (now - last_input) < IDLE_SECS
LED = 0   otherwise
```

Two pieces of state, each with exactly one writer:

| State | Meaning | Written by |
|---|---|---|
| `L` | the user's chosen level (0-3); 0 = user turned it off | **only** the `up`/`down`/`off` commands |
| `last_wrote` | the last value this daemon instance wrote to the LED | the daemon itself |

The daemon never reads the LED register on the hot path — it tracks what it
last wrote and trusts only that. The EC (which handles the hardware Fn keys
and clears the backlight across suspend entirely behind Linux's back) is
treated as what it is: an uncooperative device whose interference is undone,
not tracked.

Event handling:

| Event | Action |
|---|---|
| input event | `last_input = now`; if `L > 0 and last_wrote != L`, write `L` (exactly one write) |
| `up` / `down` | `L = clamp(L ± 1, 0, 3)`; persist; write LED; show OSD |
| `off` | `L = 0`; persist; write 0; show OSD |
| timer | if `last_wrote > 0` and idle ≥ `IDLE_SECS`, write 0; `last_wrote = 0` |

Key properties:

- **Suspend/resume = cache invalidation, nothing more.** The daemon freezes
  with the system; on the first input event after a wall-clock/monotonic-clock
  divergence (i.e. we slept), it sets `last_wrote = None` — "we were not in
  control during sleep, so assume we wrote nothing" — and the next keystroke
  writes `L` again. No logind hooks, no D-Bus listeners, no EC special-casing.
  (Observed failure this fixes: after resume the LED register can read 2 while
  the physical LEDs are dark — the EC dropped the write. Never trusting the
  register sidesteps this entirely.)
- **Normal typing costs zero sysfs writes** (`last_wrote == L` → skip).
  Relight after idle or sleep costs exactly one write. Commands always write
  (a deliberate press should always apply, even if the level didn't change).
- **Hardware changes are never adopted into `L`.** The EC's own Fn-key
  handling (see below) and any other out-of-band writes only affect the LED
  until the next event re-asserts the invariant. One writer for intent, ever.
- **`L` is persisted** (atomic `os.replace`) only when it changes, to
  `/var/lib/kbd-backlightd/level`. On startup the daemon reads it; if absent
  it adopts the current hardware level.
- **Performance:** the hot path is `select()` wake → read one 24-byte
  `input_event` → compare two integers in memory. No subprocesses, no disk
  reads, no LED reads, no polling. When dark the loop sleeps in `select()`
  with no timeout at all.

#### The Fn key problem

On this machine the EC consumes the keyboard-backlight Fn keys (Fn+F2/F3)
entirely in hardware: they change the LEDs but emit **zero** Linux input
events (verified: nothing on the AT keyboard, WMI hotkeys, or keyd devices),
so they can never drive an OSD or serve as an intent signal.

The F-row *does* send real F-keycodes when a modifier is held, so brightness
control is bound to **Super+F2/F3** (physical Ctrl+F2/F3 under the keyd macOS
map). The binding calls `kbd-backlight up|down`, a tiny client that sends the
command to the daemon over its control socket — keeping the daemon the single
writer of `L` and adding the Omarchy OSD.

Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + F2", "Keyboard brightness down", "kbd-backlight down", { locked = true })
o.bind("SUPER + F3", "Keyboard brightness up", "kbd-backlight up", { locked = true })
```

The EC's Fn+F2/F3 still change the hardware level, but the daemon re-asserts
`L` on the next input event, so don't use them — Super+F2/F3 is the control.

#### Install

Scripts live in [`scripts/kbd-backlight/`](scripts/kbd-backlight/):

```bash
sudo install -Dm755 scripts/kbd-backlight/kbd-backlightd /usr/local/bin/kbd-backlightd
sudo install -Dm755 scripts/kbd-backlight/kbd-backlight /usr/local/bin/kbd-backlight
sudo install -Dm644 scripts/kbd-backlight/kbd-backlightd.service /etc/systemd/system/kbd-backlightd.service
sudo systemctl daemon-reload
sudo systemctl enable --now kbd-backlightd.service
```

No Python dependencies — stdlib only.

#### Verify

```bash
systemctl status kbd-backlightd.service
journalctl -u kbd-backlightd -f        # shows the watched input devices

kbd-backlight up                       # LED +1, OSD appears
kbd-backlight down                     # LED -1
cat /var/lib/kbd-backlightd/level      # matches the LED level

# Hands off keyboard and touchpad for ~35s: LED turns off.
# Type a key or touch the touchpad: instantly back at L.
```

#### Configure

Change the idle timeout (default 30s):

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
