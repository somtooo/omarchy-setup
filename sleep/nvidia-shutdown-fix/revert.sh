#!/bin/bash
# Undo apply.sh: restore original nv-pci.c, rebuild, re-enable the override.
set -euo pipefail

VER=615.78.08
SRC=/usr/src/nvidia-$VER/kernel-open/nvidia/nv-pci.c

[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }

[ -f "$SRC.orig" ] && mv "$SRC.orig" "$SRC" && echo "Source restored."
for k in /usr/lib/modules/*/build; do
    dkms build --force "nvidia/$VER" -k "$(basename "$(dirname "$k")")"
    dkms install --force "nvidia/$VER" -k "$(basename "$(dirname "$k")")"
done
[ -f /etc/modprobe.d/gsr-nvidia.conf.disabled ] && \
    mv /etc/modprobe.d/gsr-nvidia.conf.disabled /etc/modprobe.d/gsr-nvidia.conf
echo "Reverted. Reboot to load the original driver."
