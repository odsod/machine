#!/usr/bin/env bash

# Check if tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
    exec "$SHELL"
fi

# The default session name
SESSION="primary"

# Only attach if not already inside tmux
if [[ -z "$TMUX" ]]; then
    # Create session if it doesn't exist, then attach
    exec tmux new-session -A -s "$SESSION"
else
    # We are already in tmux, just start a shell
    exec "$SHELL"
fi
