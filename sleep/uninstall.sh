#!/bin/bash
# Undo install.sh: plain lid suspend.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run as root (pkexec)"; exit 1; }

rm -f /etc/systemd/logind.conf.d/30-lid-suspend-then-hibernate.conf
systemctl reload systemd-logind
echo "Uninstalled."
