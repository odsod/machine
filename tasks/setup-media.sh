#!/usr/bin/env bash
set -euo pipefail

echo "[media] Swapping ffmpeg-free for ffmpeg..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || true

echo "[media] Upgrading multimedia group..."
sudo dnf group upgrade -y multimedia \

echo "[media] Installing codec packages..."
sudo dnf install -y -q \
