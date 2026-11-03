#!/usr/bin/env bash
# Save every Tailscale peer as a Herdr machine. The Herdr TUI (`herdr machine`)
# and the Herdr app (`hc machine`) keep separate lists, so both are filled.
set -euo pipefail

log() { echo "[herdr:sync-machines] $*"; }

if ! command -v tailscale >/dev/null 2>&1; then
  log "tailscale not found; skipping"
  exit 0
fi

status_json="$(tailscale status --json 2>/dev/null || true)"
backend_state="$(jq -r '.BackendState // empty' <<<"$status_json")"
if [ "$backend_state" != "Running" ]; then
  log "Tailscale state is '$backend_state'; skipping"
  exit 0
fi

peers="$(jq -r '
  .Self as $self |
  (.Peer // {})[] |
  select(
    .UserID == $self.UserID and
    (.OS == "linux" or .OS == "darwin") and
    .HostName != null and
    .HostName != "" and
    .HostName != $self.HostName
  ) |
  .HostName
' <<<"$status_json" | sort -u)"

# sync <name> <existing targets> <retry hint> <add command...>
# Runs the add command for every peer not in the existing targets, with each
# `{}` in it replaced by the peer.
sync() {
  local name="$1" existing="$2" hint="$3" peer added=0 failed=0
  shift 3
  for peer in $peers; do
    grep -Fxq "$peer" <<<"$existing" && continue
    if timeout 60s "${@//\{\}/$peer}" </dev/null >/dev/null 2>&1; then
      added=$((added + 1))
    else
      failed=$((failed + 1))
      log "could not add $peer to $name (unreachable or setup needed)" >&2
    fi
  done
  [ "$added" -eq 0 ] || log "Added $added machine(s) to $name"
  [ "$failed" -eq 0 ] || log "$failed machine(s) not added to $name; retry with: $hint" >&2
}

# Read the supported list commands, not the internal catalog files: their
# shape is not a stable interface.
if command -v herdr >/dev/null 2>&1; then
  sync "Herdr TUI" "$(herdr machine list --json | jq -r '.[].target')" \
    "herdr machine add <target>" \
    herdr machine add {} --label {} --remote-session default
else
  log "herdr not found; skipping Herdr TUI machines"
fi

# No --install: that copies hc onto the other machine.
if command -v hc >/dev/null 2>&1; then
  sync "Herdr app" "$(hc machine ls --json | jq -r '.machines[].target')" \
    "hc machine add <target> --install" \
    hc machine add {}
else
  log "hc not found; skipping Herdr app machines"
fi
