#!/usr/bin/env fish

set -l self (tailscale status --json | jq -r '.Self.HostName')
set -l host (tailscale status --json \
    | jq -r --arg self "$self" '.Peer | to_entries[] | .value | select(.Online == true) | .HostName | select(. != $self)' \
    | fzf --prompt="remote-tmux> " --height=~50% --reverse)

test -n "$host"; or exit 0

ssh -A "$host" -t tmux new-session -A -s main
