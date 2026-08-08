#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

# Source env.sh for ODSOD_HAS_RADEON_DGPU
. "$REPO_DIR/env.sh"

if [ "${ODSOD_HAS_RADEON_DGPU:-0}" != "1" ]; then
fi

echo "[gpu-services] Installing ROCm build dependencies..."
sudo dnf install -y \

# --- llama.cpp ---
LLAMA_VERSION="b10327"
LLAMA_MODEL="Qwen3.5-9B-Q5_K_M.gguf"
LLAMA_MODEL_URL="https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/${LLAMA_MODEL}"
LLAMA_EMBED_MODEL="Qwen3-Embedding-0.6B-Q8_0.gguf"
LLAMA_EMBED_MODEL_URL="https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/${LLAMA_EMBED_MODEL}"
LLAMA_PORT="8179"
LLAMA_EMBED_PORT="8180"
LLAMA_SRC="$REPO_DIR/llama/llama.cpp-${LLAMA_VERSION}"
LLAMA_BUILD="$LLAMA_SRC/build"

if [ ! -d "$LLAMA_SRC" ]; then
fi

echo "[gpu-services] Building llama-server with ROCm/HIP..."
cd "$LLAMA_SRC"
cmake -B build \
cmake --build build --target llama-server -j"$(nproc)"

if [ ! -f "${DATA_DIR}/llama/${LLAMA_MODEL}" ]; then
fi

if [ ! -f "${DATA_DIR}/llama/${LLAMA_EMBED_MODEL}" ]; then
fi

echo "[gpu-services] Installing llama systemd user services..."
mkdir -p "$HOME/.config/systemd/user"
sed \
sed \
systemctl --user daemon-reload
systemctl --user enable --now llama-server.service
systemctl --user enable --now llama-embed.service

# --- whisper.cpp ---
WHISPER_VERSION="1.9.2"
WHISPER_MODEL="ggml-large-v3.bin"
WHISPER_MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${WHISPER_MODEL}"
WHISPER_VAD_MODEL="ggml-silero-v6.2.0.bin"
WHISPER_VAD_URL="https://huggingface.co/ggml-org/whisper-vad/resolve/main/${WHISPER_VAD_MODEL}"
WHISPER_PORT="8178"
WHISPER_SRC="$REPO_DIR/whisper/whisper.cpp-${WHISPER_VERSION}"
WHISPER_BUILD="$WHISPER_SRC/build"

if [ ! -d "$WHISPER_SRC" ]; then
fi

echo "[gpu-services] Building whisper-server with ROCm/HIP..."
cd "$WHISPER_SRC"
cmake -B build \
cmake --build build --target whisper-server -j"$(nproc)"

if [ ! -f "${DATA_DIR}/whisper/${WHISPER_MODEL}" ]; then
fi

if [ ! -f "${DATA_DIR}/whisper/${WHISPER_VAD_MODEL}" ]; then
fi

echo "[gpu-services] Installing whisper systemd user service..."
sed \
systemctl --user daemon-reload
systemctl --user enable --now whisper-server.service

echo "[gpu-services] Done"
