#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mise run -C "$REPO_DIR/llama" clean
mise run -C "$REPO_DIR/whisper" clean

echo "[clean] Done"
