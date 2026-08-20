#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

. "$REPO_DIR/env.sh"

if [ "${ODSOD_HAS_RADEON_DGPU:-0}" != "1" ]; then
  echo "[whisper] Skipping: no dedicated Radeon GPU detected"
  exit 0
fi

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/whisper/mise.toml")"
MODEL="ggml-large-v3.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL}"
VAD_MODEL="ggml-silero-v6.2.0.bin"
VAD_MODEL_URL="https://huggingface.co/ggml-org/whisper-vad/resolve/main/${VAD_MODEL}"
PORT="8178"
SRC="$REPO_DIR/whisper/whisper.cpp-${VERSION}"
BUILD="$SRC/build"

echo "[whisper] Installing ROCm build dependencies..."
sudo dnf install -y -q \
  cmake \
  gcc-c++ \
  hipblas-devel \
  hipcc \
  rocblas-devel \
  rocm-hip

if [ ! -f "$SRC/CMakeLists.txt" ]; then
  rm -rf "$SRC"
  echo "[whisper] Downloading source..."
  curl -fL "https://github.com/ggerganov/whisper.cpp/archive/refs/tags/${VERSION}.tar.gz" | tar xz -C "$REPO_DIR/whisper"
fi

echo "[whisper] Building whisper-server with ROCm/HIP..."
cd "$SRC"
cmake -B build \
  -DWHISPER_BUILD_SERVER=ON \
  -DGGML_HIP=ON \
  -DCMAKE_HIP_ARCHITECTURES=gfx1200 \
  -DGGML_NATIVE=ON \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --target whisper-server -j"$(nproc)"

if [ ! -f "${DATA_DIR}/whisper/${MODEL}" ]; then
  echo "[whisper] Downloading model..."
  curl -fL "$MODEL_URL" --create-dirs -o "${DATA_DIR}/whisper/${MODEL}.tmp"
  mv "${DATA_DIR}/whisper/${MODEL}.tmp" "${DATA_DIR}/whisper/${MODEL}"
fi

if [ ! -f "${DATA_DIR}/whisper/${VAD_MODEL}" ]; then
  echo "[whisper] Downloading VAD model..."
  curl -fL "$VAD_MODEL_URL" --create-dirs -o "${DATA_DIR}/whisper/${VAD_MODEL}.tmp"
  mv "${DATA_DIR}/whisper/${VAD_MODEL}.tmp" "${DATA_DIR}/whisper/${VAD_MODEL}"
fi

echo "[whisper] Installing systemd user service..."
mkdir -p "$HOME/.config/systemd/user"
sed \
  -e "s|@SERVER_BIN@|${BUILD}/bin/whisper-server|" \
  -e "s|@MODEL_PATH@|${DATA_DIR}/whisper/${MODEL}|" \
  -e "s|@VAD_MODEL_PATH@|${DATA_DIR}/whisper/${VAD_MODEL}|" \
  -e "s|@PORT@|${PORT}|" \
  "$REPO_DIR/whisper/whisper-server.service" > "$HOME/.config/systemd/user/whisper-server.service"
systemctl --user daemon-reload
systemctl --user enable --now whisper-server.service

echo "[whisper] Done"
