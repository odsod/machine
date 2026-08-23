#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/odsod/machine/data"

# Each install task keeps its payload under data/<app>/<version>, so anything
# beside the pinned version is a leftover from an earlier bump.
prune() {
  local app="$1" keep="$2" dir
  [ -d "$DATA_DIR/$app" ] || return 0
  for dir in "$DATA_DIR/$app"/*; do
    if [ -d "$dir" ] && [ ! -L "$dir" ] && [ "$(basename "$dir")" != "$keep" ]; then
      echo "[clean] Removing $dir ($(du -sh "$dir" | cut -f1))"
      rm -rf "$dir"
    fi
  done
}

prune inter "$PINNED_INTER"
prune iosevka "$PINNED_IOSEVKA"
prune nerd-fonts "$PINNED_NERD_FONTS"
prune obsidian "$PINNED_OBSIDIAN"
prune zed "$PINNED_ZED"
prune soap-ui "$PINNED_SOAP_UI"

mise run -C "$REPO_DIR/llama" clean
mise run -C "$REPO_DIR/whisper" clean

echo "[clean] Done"
