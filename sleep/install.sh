#!/bin/bash
# Deep (S3) suspend, lid close -> suspend-then-hibernate, and the BERT
# hibernate guard. Run as root: pkexec ./sleep/install.sh
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
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

install -m 0755 "$DIR/hibernate-guard/hibernate-guard" /usr/local/bin/hibernate-guard
install -m 0644 "$DIR/hibernate-guard/hibernate-guard.service" /etc/systemd/system/
install -m 0644 "$DIR/hibernate-guard/hibernate-guard-notify.service" /etc/systemd/user/
systemctl daemon-reload
systemctl enable hibernate-guard.service
systemctl --global enable hibernate-guard-notify.service

# Apply now: run the guard for this boot (no-op without BERT), then reload logind.
/usr/local/bin/hibernate-guard
systemctl reload systemd-logind
echo "Installed."
