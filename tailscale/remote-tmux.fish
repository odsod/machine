#!/usr/bin/env fish

set -l status_json (tailscale status --json)
set -l state (echo $status_json | jq -r '.BackendState')

if test "$state" = "NeedsLogin"
    set_color red
    echo "Error: Tailscale is not authenticated."
    set_color normal
    echo "Please run 'sudo tailscale up' to log in."
    exit 1
end

set -l self_id (echo $status_json | jq -r '.Self.ID')
set -l host (echo $status_json \
    | jq -r --arg self_id "$self_id" '(.Peer // {}) | to_entries[] | .value | select(.Online == true and .ID != $self_id) | (.DNSName // .TailscaleIPs[0] // .HostName) | rtrimstr(".")' \
    | fzf --prompt="remote-tmux> " --height=~50% --reverse)

test -n "$host"; or exit 0

ssh -A "$host" -t tmux new-session -A -s main
