#!/usr/bin/env bash
# Disk swap tier. Sizes are per host; unlisted hosts keep Fedora's zram-only
# default. The swapfile is headroom against OOM, not capacity.
#
# Every host runs Fedora Workstation, so the root is btrfs on LUKS and
# `btrfs filesystem mkswapfile` handles the nodatacow and preallocation rules
# that btrfs requires of a swapfile.
set -euo pipefail

case "$(uname -n)" in
odsod-desktop) size=64G ;;
odsod-x1-carbon) size=48G ;;
*)
  echo "[swap] $(uname -n) is unlisted; keeping zram only"
  exit 0
  ;;
esac

path=/swap/swapfile
target_bytes=$(numfmt --from=iec "$size")

if [ ! -e "$path" ] || [ "$(stat -c %s "$path" 2>/dev/null || echo 0)" -ne "$target_bytes" ]; then
  echo "[swap] creating $path ($size)"
  sudo swapoff "$path" 2>/dev/null || true
  sudo rm -f "$path"
  sudo mkdir -p "$(dirname "$path")"
  sudo btrfs filesystem mkswapfile --size "$size" "$path"
fi

if command -v selinuxenabled >/dev/null && selinuxenabled; then
  if ! matchpathcon -n "$path" 2>/dev/null | grep -q 'swapfile_t'; then
    echo "[swap] adding SELinux file context for /swap"
    sudo semanage fcontext -a -t swapfile_t '/swap(/.*)?'
  fi
  sudo restorecon -RF "$(dirname "$path")"
fi

# The fstab entry is a [bootstrap.files] block now. Drop the lines this script
# used to append. Remove this once every host has applied it.
if grep -qxF "$path none swap sw,pri=50 0 0" /etc/fstab; then
  echo "[swap] removing the old $path lines from /etc/fstab"
  sudo sed -i -e '\|^# Disk swap tier, managed by odsod/machine$|d' \
    -e "\\|^$path none swap sw,pri=50 0 0\$|d" /etc/fstab
  sudo systemctl daemon-reload
fi

sudo swapon -a
swapon --show=NAME,TYPE,SIZE,USED,PRIO
