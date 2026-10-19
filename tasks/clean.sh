#!/usr/bin/env bash
set -euo pipefail

mise run llama:clean
mise run whisper:clean

echo "[clean] Done"
