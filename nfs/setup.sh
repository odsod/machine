#!/usr/bin/env bash
set -euo pipefail

# A process stuck on an unreachable NFS server cannot be frozen, so suspend
# waits 60 s for the user.slice freeze and service watchdogs expire. Force
# unmount NFS before every sleep; automount mounts it again on the next use.
unit=/etc/systemd/system/nfs-unmount-before-sleep.service
want=$(
  cat <<'UNIT'
[Unit]
Description=Unmount NFS before sleep so a dead server cannot block the freeze
Before=sleep.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/bin/umount -a -f -l -t nfs,nfs4

[Install]
WantedBy=sleep.target
UNIT
)
if [ "$(cat "$unit" 2>/dev/null)" != "$want" ]; then
  echo "[nfs] Installing $unit"
  echo "$want" | sudo tee "$unit" >/dev/null
  sudo systemctl daemon-reload
fi
sudo systemctl enable --quiet nfs-unmount-before-sleep.service

# Laptops reach the NAS away from home through the media server's tailnet
# subnet route (192.168.1.158/32, see the house repo). The desktop stays on
# the LAN.
if [ "$(uname -n)" = "odsod-desktop" ]; then
  exit 0
fi
if [ "$(tailscale debug prefs 2>/dev/null | jq -r '.RouteAll')" != "true" ]; then
  echo "[nfs] Accepting tailnet routes"
  tailscale set --accept-routes
fi
