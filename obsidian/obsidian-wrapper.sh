#!/bin/sh
set -e

APP="$(readlink -f "$(command -v obsidian-app 2>/dev/null || echo "$HOME/.local/bin/obsidian-app")")"
if [ ! -f "$APP" ]; then
    echo "error: obsidian-app not found" >&2
    exit 1
fi
[ -x "$APP" ] || chmod +x "$APP"

CLI_BIN="$(dirname "$APP")/obsidian-cli"
if [ ! -x "$CLI_BIN" ]; then
    TMP_DIR="$(mktemp -d)"
    (cd "$TMP_DIR" && "$APP" --appimage-extract obsidian-cli >/dev/null 2>&1)
    install -m 755 "$TMP_DIR/squashfs-root/obsidian-cli" "$CLI_BIN"
    rm -rf "$TMP_DIR"
    ln -fsT "$CLI_BIN" "$HOME/.local/bin/obsidian-cli"
elif [ ! -e "$HOME/.local/bin/obsidian-cli" ]; then
    ln -fsT "$CLI_BIN" "$HOME/.local/bin/obsidian-cli"
fi

CLI="${OBSIDIAN_CLI:-$CLI_BIN}"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/.obsidian-cli.sock"
DEFAULT_VAULT="odsod"

if [ ! -S "$SOCK" ]; then
    mkdir -p "$HOME/.config/obsidian"
    config="$HOME/.config/obsidian/obsidian.json"
    [ -f "$config" ] || echo '{}' > "$config"
    jq --arg path "$HOME/Vaults/odsod" \
      'if (.vaults // {} | to_entries | map(select(.value.path == $path)) | length) == 0
       then .vaults.odsod = {"path": $path, "open": true} else . end | .cli = true' \
      "$config" > "$config.tmp" && mv "$config.tmp" "$config"

    WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" obsidian-app >/dev/null 2>&1 &
    timeout=30
    while [ ! -S "$SOCK" ] && [ "$timeout" -gt 0 ]; do
        sleep 0.5
        timeout=$((timeout - 1))
    done
    if [ ! -S "$SOCK" ]; then
        echo "error: timed out waiting for Obsidian to start" >&2
        exit 1
    fi
    # Wait for vault to be ready (socket exists before vault loads)
    attempts=20
    while [ "$attempts" -gt 0 ]; do
        if "$CLI" vault="$DEFAULT_VAULT" vault info=name >/dev/null 2>&1; then
            break
        fi
        sleep 0.5
        attempts=$((attempts - 1))
    done
fi

# Ensure vault is targeted even on cold start
case "$*" in
    *vault=*) exec "$CLI" "$@" ;;
    *)        exec "$CLI" vault="$DEFAULT_VAULT" "$@" ;;
esac
