#!/usr/bin/env bash
# Point links into tool installs at the versions this config selects. A
# postinstall link follows whichever version installed last, so an older pin
# from another workspace can move it back, and prune then leaves it dangling.
# Run from apply, as herdr:setup-core does for hc.
set -euo pipefail

log() { echo "[tools:link] $*"; }

link() {
  local target=$1 link=$2
  if [ ! -e "$target" ]; then
    log "Missing $target; not linking $link" >&2
    return
  fi
  if [ "$(readlink "$link" 2>/dev/null)" != "$target" ]; then
    mkdir -p "$(dirname "$link")"
    ln -fsT "$target" "$link"
    log "Linked $link to $target"
  fi
}

bin="$HOME/.local/bin"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

nvim="$(mise where neovim)/bin/nvim"
link "$nvim" "$bin/vim"
link "$nvim" "$bin/vi"
link "$(mise where http:soap-ui)/bin/soapui.sh" "$bin/soap-ui"
obsidian="$(mise where http:obsidian)"
link "$(echo "$obsidian"/Obsidian-*.AppImage)" "$bin/obsidian-app"
# The obsidian wrapper extracts obsidian-cli next to the AppImage on first use.
[ -e "$obsidian/obsidian-cli" ] && link "$obsidian/obsidian-cli" "$bin/obsidian-cli"
link "$(mise where http:vibetyper)/VibeTyper.AppImage" "$bin/vibetyper"
link "$(mise where http:herdr-app)/herdr-app.svg" "$data/icons/hicolor/scalable/apps/herdr-app.svg"
# gh runs `gh stack` only from its extension dir. A symlinked dir is a local
# extension, which `gh extension upgrade` refuses to touch.
link "$(mise where github:github/gh-stack)" "$data/gh/extensions/gh-stack"
