#!/usr/bin/env bash
set -euo pipefail

mise run llama:clean
mise run whisper:clean

# Forget tracked config links to deleted files (old workspaces).
mise prune --configs

echo "[clean] Done"
