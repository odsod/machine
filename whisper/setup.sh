#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

. "$REPO_DIR/env.sh"

if [ "${ODSOD_HAS_RADEON_DGPU:-0}" != "1" ]; then
  echo "[whisper] Skipping: no dedicated Radeon GPU detected"
  exit 0
fi

VERSION="${WHISPER_VERSION:?run via mise run whisper:setup}"
MODEL="${WHISPER_MODEL:?run via mise run whisper:setup}"
MODEL_URL="${WHISPER_MODEL_URL:?run via mise run whisper:setup}"
VAD_MODEL="${WHISPER_VAD_MODEL:?run via mise run whisper:setup}"
VAD_MODEL_URL="${WHISPER_VAD_MODEL_URL:?run via mise run whisper:setup}"
PORT="${WHISPER_PORT:?run via mise run whisper:setup}"
SRC="$DATA_DIR/whisper/whisper.cpp-${VERSION}"
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
  mkdir -p "$DATA_DIR/whisper"
  echo "[whisper] Downloading source..."
  curl -fL "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v${VERSION}.tar.gz" | tar xz -C "$DATA_DIR/whisper"
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
UNIT_FILE="$HOME/.config/systemd/user/whisper-server.service"
OLD_UNIT="$(cat "$UNIT_FILE" 2>/dev/null || true)"
sed \
  -e "s|@SERVER_BIN@|${BUILD}/bin/whisper-server|" \
  -e "s|@MODEL_PATH@|${DATA_DIR}/whisper/${MODEL}|" \
  -e "s|@VAD_MODEL_PATH@|${DATA_DIR}/whisper/${VAD_MODEL}|" \
  -e "s|@PORT@|${PORT}|" \
  "$REPO_DIR/whisper/whisper-server.service" > "$UNIT_FILE"
systemctl --user daemon-reload
systemctl --user enable --now whisper-server.service

# `enable --now` does not restart a running service, so a rebuilt binary would
# sit unused. Restart when the installed version or unit file changed.
STAMP="$DATA_DIR/whisper/.installed-version"
if [ "$(cat "$STAMP" 2>/dev/null || true)" != "$VERSION" ] || [ "$(cat "$UNIT_FILE")" != "$OLD_UNIT" ]; then
  systemctl --user restart whisper-server.service
  mkdir -p "$DATA_DIR/whisper"
  printf '%s\n' "$VERSION" > "$STAMP"
fi

echo "[whisper] Done"
