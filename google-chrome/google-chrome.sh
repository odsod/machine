#!/bin/bash
# Google Chrome's official RPM does not support chrome-flags.conf natively.
# This wrapper implements the Arch Linux convention:
# https://wiki.archlinux.org/title/Chromium#Making_flags_persistent
export CHROME_WRAPPER="$(readlink -f "$0")"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/chrome-flags.conf"
FLAGS=()
if [ -f "$CONF" ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*#.*$ || -z "$line" ]] && continue
        read -ra words <<< "$line"
        FLAGS+=("${words[@]}")
    done < "$CONF"
fi
exec /usr/bin/google-chrome "${FLAGS[@]}" "$@"
