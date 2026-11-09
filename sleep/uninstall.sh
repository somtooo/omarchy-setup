#!/bin/bash
# Undo install.sh: back to s2idle, plain lid suspend, no hibernate guard.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run as root (pkexec)"; exit 1; }

systemctl disable hibernate-guard.service || true
systemctl --global disable hibernate-guard-notify.service || true
rm -f /etc/systemd/sleep.conf.d/mem-sleep-deep.conf \
      /etc/systemd/logind.conf.d/30-lid-suspend-then-hibernate.conf \
      /etc/systemd/system/hibernate-guard.service \
      /etc/systemd/user/hibernate-guard-notify.service \
      /usr/local/bin/hibernate-guard \
      /run/systemd/sleep.conf.d/90-hibernate-guard.conf \
      /run/systemd/logind.conf.d/90-hibernate-guard.conf \
      /run/hibernate-guard-active
systemctl daemon-reload
systemctl reload systemd-logind
echo "Uninstalled."
