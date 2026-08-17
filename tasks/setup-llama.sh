#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

. "$REPO_DIR/env.sh"

if [ "${ODSOD_HAS_RADEON_DGPU:-0}" != "1" ]; then
  echo "[llama] Skipping: no dedicated Radeon GPU detected"
  exit 0
fi

VERSION="b10453"
MODEL="Qwen3.5-9B-Q5_K_M.gguf"
MODEL_URL="https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/${MODEL}"
EMBED_MODEL="Qwen3-Embedding-0.6B-Q8_0.gguf"
EMBED_MODEL_URL="https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/${EMBED_MODEL}"
PORT="8179"
EMBED_PORT="8180"
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
  curl -fL "https://github.com/ggml-org/llama.cpp/archive/refs/tags/${VERSION}.tar.gz" | tar xz -C "$REPO_DIR/llama"
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

if [ ! -f "${DATA_DIR}/llama/${EMBED_MODEL}" ]; then
  echo "[llama] Downloading embedding model..."
  curl -fL "$EMBED_MODEL_URL" --create-dirs -o "${DATA_DIR}/llama/${EMBED_MODEL}.tmp"
  mv "${DATA_DIR}/llama/${EMBED_MODEL}.tmp" "${DATA_DIR}/llama/${EMBED_MODEL}"
fi

echo "[llama] Installing systemd user services..."
mkdir -p "$HOME/.config/systemd/user"
sed \
  -e "s|@SERVER_BIN@|${BUILD}/bin/llama-server|" \
  -e "s|@MODEL_PATH@|${DATA_DIR}/llama/${MODEL}|" \
  -e "s|@PORT@|${PORT}|" \
  "$REPO_DIR/llama/llama-server.service" > "$HOME/.config/systemd/user/llama-server.service"
sed \
  -e "s|@SERVER_BIN@|${BUILD}/bin/llama-server|" \
  -e "s|@MODEL_PATH@|${DATA_DIR}/llama/${EMBED_MODEL}|" \
  -e "s|@PORT@|${EMBED_PORT}|" \
  "$REPO_DIR/llama/llama-embed.service" > "$HOME/.config/systemd/user/llama-embed.service"
systemctl --user daemon-reload
systemctl --user enable --now llama-server.service
systemctl --user enable --now llama-embed.service

echo "[llama] Done"
