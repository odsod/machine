#!/bin/bash
# Wrapper that injects platform flags from chrome-flags.conf before
# delegating to the real google-chrome binary.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/chrome-flags.conf"
FLAGS=()
if [ -f "$CONF" ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*#.*$ || -z "$line" ]] && continue
        FLAGS+=("$line")
    done < "$CONF"
fi
exec /usr/bin/google-chrome "${FLAGS[@]}" "$@"
