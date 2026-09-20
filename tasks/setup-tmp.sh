#!/usr/bin/env bash
# Move /tmp off tmpfs onto the encrypted root btrfs.
#
# A tmpfs page has no copy anywhere else, so the kernel cannot drop it. To
# reuse that RAM it must write the page to swap first, and swap here is zram,
# which is RAM. Temp files in /tmp therefore hold memory that agents and
# builds need. The same pages on disk are ordinary page cache, which the
# kernel drops for free.
#
# The mask takes effect at the next boot. Until then /tmp stays tmpfs, and
# whatever is in it now is lost at that reboot.
set -euo pipefail

if [ "$(systemctl is-enabled tmp.mount 2>/dev/null || true)" = "masked" ]; then
  echo "[tmp] tmp.mount is already masked"
else
  echo "[tmp] masking tmp.mount"
  sudo systemctl mask tmp.mount
fi

if [ "$(findmnt -no FSTYPE /tmp)" = "tmpfs" ]; then
  echo "[tmp] /tmp is still tmpfs; reboot to move it onto the root btrfs"
fi
