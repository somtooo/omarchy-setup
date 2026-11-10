#!/bin/bash
# Lid close -> suspend-then-hibernate (s2idle, then hibernate after
# HibernateDelaySec). Run as root: pkexec ./sleep/install.sh
#
# Do NOT set MemorySleepMode=deep: after ~35 min in S3 the RTX 5070 Ti's GSP
# firmware fails to boot on resume ("GSP boot failed at resume") and the GPU
# is lost. s2idle has been reliable across ~170 suspends.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "Run as root (pkexec)"; exit 1; }

mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/30-lid-suspend-then-hibernate.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
EOF

# Reload (not restart) so the running session survives.
systemctl reload systemd-logind
echo "Installed."
