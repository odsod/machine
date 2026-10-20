#!/bin/sh
# Verify the amdgpu RA24 / KWin atomic-commit fix.
#
# Root cause: amdgpu advertises DRM_FORMAT_RGBA8888 in rgb_formats[] and
# overlay_formats[] (amdgpu_dm_plane.c) but fill_plane_buffer_attributes()
# has no case for it (amdgpu_dm.c), so the atomic commit fails with
# "Unsupported screen format RA24" and KWin retries until the desktop wedges.
#
# Fix in place:
#   session KWin  - KWIN_USE_OVERLAYS=1 via ~/.config/plasma-workspace/env/
#                   odsod-machine.sh (env.sh in the machine repo)
#   login greeter - KWIN_USE_OVERLAYS=1 via the drop-in at
#                   /etc/systemd/user/plasma-login-kwin_wayland.service.d/
#
# Run this after logging in with the LG HDMI monitor connected and ENABLED.
# A connected-but-disabled output proves nothing: nothing scans out to it.

set -u

pass=0
fail=0

ok() {
  printf '  ok    %s\n' "$1"
  pass=$((pass + 1))
}

bad() {
  printf '  FAIL  %s\n' "$1"
  fail=$((fail + 1))
}

note() {
  printf '  note  %s\n' "$1"
}

# Detect the GPU directly. Sourcing env.sh is unreliable here because it
# returns early when ODSOD_MACHINE is already exported, leaving
# ODSOD_HAS_RADEON_DGPU stale. Override with ODSOD_HAS_RADEON_DGPU=0/1.
if [ -z "${ODSOD_HAS_RADEON_DGPU:-}" ]; then
  ODSOD_HAS_RADEON_DGPU=0
  if command -v lspci >/dev/null 2>&1 &&
    lspci -nn -d 1002: 2>/dev/null |
    grep -Eqi '(VGA compatible controller|3D controller|Display controller).*(Radeon RX|Radeon PRO|Radeon VII|Radeon Instinct)'; then
    ODSOD_HAS_RADEON_DGPU=1
  fi
fi
export ODSOD_HAS_RADEON_DGPU

echo "== 1. Session KWin has overlays forced on (Radeon dGPU machines only) =="
env_out=$(systemctl --user show-environment 2>/dev/null)
val=$(printf '%s\n' "$env_out" | sed -n 's/^KWIN_USE_OVERLAYS=//p' | head -1)
if [ "${ODSOD_HAS_RADEON_DGPU:-0}" = "1" ]; then
  if [ "$val" = "1" ]; then
    ok "KWIN_USE_OVERLAYS=1"
  else
    bad "KWIN_USE_OVERLAYS is '${val:-unset}', expected 1"
  fi
else
  if [ -n "$val" ]; then
    bad "KWIN_USE_OVERLAYS=$val set on a machine without a Radeon dGPU"
  else
    ok "KWIN_USE_OVERLAYS unset, correct for this hardware"
  fi
fi

echo
echo "== 2. Greeter KWin drop-in installed (Radeon dGPU machines only) =="
dropin=/etc/systemd/user/plasma-login-kwin_wayland.service.d/50-amdgpu-ra24.conf
if [ "${ODSOD_HAS_RADEON_DGPU:-0}" = "1" ]; then
  if [ -r "$dropin" ] && grep -q 'KWIN_USE_OVERLAYS=1' "$dropin"; then
    ok "drop-in present with KWIN_USE_OVERLAYS=1"
  else
    bad "drop-in missing or lacks KWIN_USE_OVERLAYS=1"
  fi
else
  if [ -e "$dropin" ]; then
    bad "drop-in present on a machine without a Radeon dGPU - run kwin:greeter-dropin"
  else
    ok "no drop-in, correct for this hardware"
  fi
fi

echo
echo "== 3. HDMI output ENABLED, not merely connected =="
enabled_out=""
connected_out=""
for c in /sys/class/drm/card*-HDMI-A-*; do
  [ -e "$c" ] || continue
  name=$(basename "$c")
  if [ "$(cat "$c/status" 2>/dev/null)" = "connected" ]; then
    connected_out=$name
    if [ "$(cat "$c/enabled" 2>/dev/null)" = "enabled" ]; then
      enabled_out=$name
    fi
  fi
done
if [ -n "$enabled_out" ]; then
  ok "HDMI output enabled and scanning out: $enabled_out"
elif [ -n "$connected_out" ]; then
  bad "$connected_out is connected but DISABLED - nothing scans out, test is void"
else
  bad "no HDMI output connected - plug the LG in to test"
fi

echo
echo "== 4. No RA24 errors this boot =="
n=$(journalctl -k -b 0 --no-pager 2>/dev/null | grep -c 'Unsupported screen format RA24' || true)
if [ "${n:-0}" -eq 0 ]; then
  ok "0 RA24 errors"
else
  bad "$n RA24 errors"
  journalctl -k -b 0 --no-pager 2>/dev/null |
    grep 'Unsupported screen format RA24' | tail -3 | sed 's/^/        /'
fi

echo
echo "== 5. No KWin atomic commit failures this boot =="
n=$(journalctl -b 0 --no-pager 2>/dev/null |
  grep -c 'Atomic modeset commit failed' || true)
if [ "${n:-0}" -eq 0 ]; then
  ok "0 atomic commit failures"
else
  bad "$n atomic commit failures"
  journalctl -b 0 --no-pager 2>/dev/null |
    grep 'Atomic modeset commit failed' | tail -3 | sed 's/^/        /'
fi

echo
echo "== 6. EDID readable on HDMI =="
n=$(journalctl -b 0 --no-pager 2>/dev/null | grep -c 'Could not find edid' || true)
if [ "${n:-0}" -eq 0 ]; then
  ok "0 EDID read failures"
else
  bad "$n EDID read failures - check the cable and Ultra HD Deep Colour"
fi

echo
printf 'summary: %s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
