#!/bin/bash
# Wrapper for odsod Dvorak layout: translate Ctrl+V/Ctrl+Shift+V
# to correct evdev keycodes for the odsod XKB layout.
# 'v' is at physical position AB09 = evdev keycode 52.
for arg in "$@"; do
    if [[ "$arg" == "--portal" ]]; then
        exit 1
    fi
done

if [[ "$1" == "--uinput" ]]; then
    if [[ "$2" == "--terminal" ]]; then
        # Ctrl+Shift+V for terminals
        ydotool key 29:1 42:1 52:1 52:0 42:0 29:0
    else
        # Ctrl+V
        ydotool key 29:1 52:1 52:0 29:0
    fi
    exit $?
fi

exec /opt/OpenWhispr/resources/bin/linux-fast-paste.real "$@"
