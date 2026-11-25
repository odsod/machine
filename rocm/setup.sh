#!/usr/bin/env bash
set -euo pipefail

# ROCm build packages for the inference servers. The odsod/daemon repo builds
# and runs whisper-server and llama-server (`odsodctl inference setup`).
# Only the desktop has the Radeon RX 9060 XT (gfx1200).
if [ "$(uname -n)" != "odsod-desktop" ]; then
  echo "[rocm] Skipping: $(uname -n) is not odsod-desktop"
  exit 0
fi

echo "[rocm] Installing ROCm build packages..."
sudo dnf install -y -q \
  cmake \
  gcc-c++ \
  hipblas-devel \
  hipcc \
  rocblas-devel \
  rocm-hip
