#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

. "$REPO_DIR/env.sh"

if [ "${ODSOD_HAS_RADEON_DGPU:-0}" != "1" ]; then
  echo "[llama] Skipping: no dedicated Radeon GPU detected"
  exit 0
fi

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/llama/mise.toml")"
MODEL="Qwen3.5-9B-Q5_K_M.gguf"
MODEL_URL="https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/${MODEL}"
PORT="8179"
SRC="$REPO_DIR/llama/llama.cpp-${VERSION}"
BUILD="$SRC/build"

echo "[llama] Installing ROCm build dependencies..."
sudo dnf install -y -q \
  cmake \
  gcc-c++ \
  hipblas-devel \
  hipcc \
  rocblas-devel \
  rocm-hip

if [ ! -f "$SRC/CMakeLists.txt" ]; then
  rm -rf "$SRC"
  echo "[llama] Downloading source..."
  curl -fL "https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${VERSION}.tar.gz" | tar xz -C "$REPO_DIR/llama"
fi

echo "[llama] Building llama-server with ROCm/HIP..."
cd "$SRC"
cmake -B build \
  -DGGML_HIP=ON \
  -DCMAKE_HIP_ARCHITECTURES=gfx1200 \
  -DGGML_NATIVE=ON \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --target llama-server -j"$(nproc)"

if [ ! -f "${DATA_DIR}/llama/${MODEL}" ]; then
  echo "[llama] Downloading model..."
  curl -fL "$MODEL_URL" --create-dirs -o "${DATA_DIR}/llama/${MODEL}.tmp"
  mv "${DATA_DIR}/llama/${MODEL}.tmp" "${DATA_DIR}/llama/${MODEL}"
fi

echo "[llama] Installing systemd user services..."
mkdir -p "$HOME/.config/systemd/user"
sed \
  -e "s|@SERVER_BIN@|${BUILD}/bin/llama-server|" \
  -e "s|@MODEL_PATH@|${DATA_DIR}/llama/${MODEL}|" \
  -e "s|@PORT@|${PORT}|" \
  "$REPO_DIR/llama/llama-server.service" > "$HOME/.config/systemd/user/llama-server.service"
if systemctl --user is-active --quiet llama-embed.service 2>/dev/null; then
  systemctl --user disable --now llama-embed.service 2>/dev/null || true
fi
rm -f "$HOME/.config/systemd/user/llama-embed.service"
systemctl --user daemon-reload
systemctl --user enable --now llama-server.service

echo "[llama] Done"
