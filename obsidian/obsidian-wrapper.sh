#!/bin/sh
set -e

SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/.obsidian-cli.sock"
CLI="$HOME/.local/share/odsod/machine/data/obsidian/current/obsidian-cli"
DEFAULT_VAULT="odsod"

if [ ! -S "$SOCK" ]; then
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
