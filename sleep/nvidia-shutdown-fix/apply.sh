#!/bin/bash
# Patch nvidia-open-dkms so hibernate (HibernateMode=shutdown) can power off.
# Fix from: https://forums.developer.nvidia.com/t/382485 (post #5)
# Skips nv_linux_stop_open_q / nvidia_modeset_remove on the shutdown path
# when the GPU is still in use. The original code bails out in that case
# anyway, just after the calls that deadlock.
set -euo pipefail

VER=615.78.08
SRC=/usr/src/nvidia-$VER/kernel-open/nvidia/nv-pci.c
MARK="Hibernate shutdown fix: skipping teardown of an in-use GPU"

[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
[ -f "$SRC" ] || { echo "Missing $SRC (driver version changed?)"; exit 1; }

if grep -q "$MARK" "$SRC"; then
    echo "Source already patched."
else
    cp -n "$SRC" "$SRC.orig"
    python3 -I - "$SRC" "$MARK" <<'EOF'
import sys
path, mark = sys.argv[1], sys.argv[2]
s = open(path).read()
anchor = """    /*
     * Flush and stop open_q before proceeding with removal to ensure nvl
     * outlives all enqueued work items.
     */
    nv_linux_stop_open_q(nvl);

    nvidia_modeset_remove(nv->gpu_id);
"""
if s.count(anchor) != 1:
    sys.exit("Anchor not found exactly once; not patching.")
fix = """    if (!block_if_gpu_in_use && (atomic64_read(&nvl->usage_count) != 0))
    {
        nv_printf(NV_DBG_ERRORS,
                  "NVRM: %s\\n");
        return;
    }

""" % mark
open(path, "w").write(s.replace(anchor, fix + anchor))
EOF
    echo "Source patched (backup: $SRC.orig)."
fi

# Rebuild for every installed kernel that has headers.
for k in /usr/lib/modules/*/build; do
    kver=$(basename "$(dirname "$k")")
    echo "== Rebuilding nvidia for $kver"
    # "install --force" alone reuses the old build; force a fresh compile.
    dkms build --force "nvidia/$VER" -k "$kver"
    dkms install --force "nvidia/$VER" -k "$kver"
    # grep -c (not -q) so the pipe isn't cut early and tripped by pipefail.
    found=$(zstd -dc "/usr/lib/modules/$kver/updates/dkms/nvidia.ko.zst" | strings \
        | grep -c "$MARK" || true)
    [ "$found" -gt 0 ] || { echo "Patch missing from built module for $kver"; exit 1; }
    echo "Verified patch is in the module for $kver."
done

# Undo the test override that forced PreserveVideoMemoryAllocations=0.
# With 0, hibernate skips writing the image; the packaged default is 1.
if [ -f /etc/modprobe.d/gsr-nvidia.conf ]; then
    mv /etc/modprobe.d/gsr-nvidia.conf /etc/modprobe.d/gsr-nvidia.conf.disabled
    echo "Disabled /etc/modprobe.d/gsr-nvidia.conf (Preserve back to 1)."
fi

echo
echo "Done. Do a full reboot (not a hibernate/resume), then test with:"
echo "  systemctl hibernate"
