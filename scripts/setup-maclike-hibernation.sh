#!/bin/bash
# setup-maclike-hibernation.sh - Fix NVIDIA hibernation resume and enable macOS-like safe sleep
# Reproduces the 2026-09-03 fix for GU605CR (Intel Ultra 9 + RTX 5070 Ti) on Omarchy 4 + Limine UKI
# See system-setup.md §19 for full diagnosis.
set -euo pipefail

echo "== NVIDIA hibernation fix (preserve video memory) =="
echo "Enabling nvidia-hibernate, nvidia-resume, nvidia-suspend, nvidia-suspend-then-hibernate"
pkexec bash -c 'systemctl enable nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service'
systemctl is-enabled nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service nvidia-suspend-then-hibernate.service || true
echo

echo "== Verify hibernation prerequisites =="
if ! omarchy hibernation available; then
  echo "omarchy hibernation available failed - checking manually:"
  echo "  SWAP:"; swapon --show; echo "  image_size:"; cat /sys/power/image_size; echo "  cmdline:"; tr " " "\n" < /proc/cmdline | grep -E "resume|rtc"
  echo "If swap < image_size, re-run: omarchy hibernation setup --force"
else
  echo "omarchy hibernation available: OK"
fi
echo "  resume device/offset:"
cat /proc/cmdline | tr " " "\n" | grep -E "resume"
cat /sys/power/resume 2>/dev/null; cat /sys/power/resume_offset 2>/dev/null
echo

echo "== Mac-like safe sleep: /etc/systemd/sleep.conf.d/10-maclike.conf =="
pkexec bash -c '
mkdir -p /etc/systemd/sleep.conf.d
cat > /etc/systemd/sleep.conf.d/10-maclike.conf << "EOF"
# Mac-like safe sleep: suspend then hibernate after delay (like macOS Standby)
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
AllowHybridSleep=no
SuspendState=mem
HibernateMode=platform shutdown
MemorySleepMode=s2idle
HibernateDelaySec=2h
HibernateOnACPower=yes
SuspendEstimationSec=60min
EOF
cat /etc/systemd/sleep.conf.d/10-maclike.conf
'
echo

echo "== Mac-like lid handling: /etc/systemd/logind.conf.d/30-maclike-lid.conf =="
# No HandlePowerKey here (stays in 10-ignore-power-button.conf)
# No IdleAction by default (Omarchy idle is shell-based: screensaver 150s / lock 300s)
pkexec bash -c '
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/30-maclike-lid.conf << "EOF"
# Mac-like lid handling: does NOT clash with Omarchy Hyprland binding.
# Hyprland Lid Switch -> omarchy-system-lid-close only locks; logind does suspend.
# Omarchy ships no HandleLidSwitch override, so this extends default suspend.
# Idle stays in omarchy.idle service, not logind.
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
HandleLidSwitchDocked=ignore
#IdleAction=ignore
#IdleActionSec=30min
EOF
cat /etc/systemd/logind.conf.d/30-maclike-lid.conf
'
echo

echo "== Effective configs =="
systemd-analyze cat-config systemd/sleep.conf | grep -A20 "10-maclike" || true
systemd-analyze cat-config systemd/logind.conf | grep -A20 "30-maclike" || true
echo

echo "Done. Reboot to apply logind changes."
echo "Verify after reboot + hibernate:"
echo "  journalctl -b 0 -k | grep -E 'PM: hibernation|nvidia.*PM:'"
echo "  journalctl -b -1 | grep -E 'PM: hibernation: hibernation entry'"
echo "To enable idle auto-suspend (optional, not default): uncomment IdleAction in 30-maclike-lid.conf"
echo "To fully revert: pkexec rm /etc/systemd/sleep.conf.d/10-maclike.conf /etc/systemd/logind.conf.d/30-maclike-lid.conf"
