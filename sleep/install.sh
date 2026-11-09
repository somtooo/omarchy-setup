#!/bin/bash
# Deep (S3) suspend, and lid close -> suspend-then-hibernate.
# Run as root: pkexec ./sleep/install.sh
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run as root (pkexec)"; exit 1; }

mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d

# s2idle keeps the SoC half-awake and drains the battery; S3 works here.
cat > /etc/systemd/sleep.conf.d/mem-sleep-deep.conf <<'EOF'
[Sleep]
MemorySleepMode=deep
EOF

cat > /etc/systemd/logind.conf.d/30-lid-suspend-then-hibernate.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
EOF

# Reload (not restart) so the running session survives.
systemctl reload systemd-logind
echo "Installed."
