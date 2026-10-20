#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DROPIN_DIR=/etc/systemd/user/plasma-login-kwin_wayland.service.d
DROPIN="$DROPIN_DIR/50-amdgpu-ra24.conf"
SOURCE="$REPO_DIR/kwin/plasma-login-kwin-amdgpu.conf"

# Detect the GPU here rather than sourcing env.sh. env.sh returns early when
# ODSOD_MACHINE is already exported, which would leave ODSOD_HAS_RADEON_DGPU
# stale or unset and silently defeat this gate. Override with
# ODSOD_HAS_RADEON_DGPU=0/1 to force either branch.
has_radeon_dgpu() {
  if [ -n "${ODSOD_HAS_RADEON_DGPU:-}" ]; then
    [ "$ODSOD_HAS_RADEON_DGPU" = "1" ]
    return
  fi
  command -v lspci >/dev/null 2>&1 || return 1
  lspci -nn -d 1002: 2>/dev/null |
    grep -Eqi '(VGA compatible controller|3D controller|Display controller).*(Radeon RX|Radeon PRO|Radeon VII|Radeon Instinct)'
}

# Only machines whose Radeon dGPU advertises the broken RGBA8888 plane format
# need this. Laptops and Intel-only machines keep the vendor unit untouched.
if ! has_radeon_dgpu; then
  echo "[kwin] Skipping greeter drop-in: no dedicated Radeon GPU detected"
  if [ -e "$DROPIN" ]; then
    echo "[kwin] Removing stale drop-in $DROPIN"
    sudo rm -f "$DROPIN"
    sudo rmdir --ignore-fail-on-non-empty "$DROPIN_DIR" 2>/dev/null || true
  fi
  exit 0
fi

if [ ! -r "$SOURCE" ]; then
  echo "[kwin] Missing $SOURCE" >&2
  exit 1
fi

echo "[kwin] Installing greeter drop-in $DROPIN"
sudo install -d -o root -g root -m 0755 "$DROPIN_DIR"
sudo install -o root -g root -m 0644 "$SOURCE" "$DROPIN"
