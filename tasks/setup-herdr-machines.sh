#!/usr/bin/env bash
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1 || ! command -v herdr >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "[herdr:sync-machines] tailscale, herdr, or jq not found; skipping"
  exit 0
fi

status_json="$(tailscale status --json 2>/dev/null || true)"
if [ -z "$status_json" ]; then
  echo "[herdr:sync-machines] Tailscale status unavailable; skipping"
  exit 0
fi

backend_state="$(printf '%s\n' "$status_json" | jq -r '.BackendState // empty')"
if [ "$backend_state" != "Running" ]; then
  echo "[herdr:sync-machines] Tailscale state is '$backend_state'; skipping"
  exit 0
fi

peers="$(printf '%s\n' "$status_json" | jq -r '
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
' | sort -u)"

# Read the supported profile list instead of the internal catalog file. Herdr
# owns that file; its shape is not a stable interface.
existing_targets="$(herdr machine list --json 2>/dev/null | jq -r '.[].target' || true)"

added=0
failed=0
for peer in $peers; do
  [ -n "$peer" ] || continue
  if printf '%s\n' "$existing_targets" | grep -Fxq "$peer"; then
    continue
  fi

  add_cmd=(herdr machine add "$peer" --label "$peer" --remote-session default)
  if command -v timeout >/dev/null 2>&1; then
    add_cmd=(timeout 30s "${add_cmd[@]}")
  fi

  if "${add_cmd[@]}" </dev/null >/dev/null 2>&1; then
    added=$((added + 1))
  else
    failed=$((failed + 1))
    echo "[herdr:sync-machines] could not add $peer (unreachable or setup needed)" >&2
  fi
done

if [ "$added" -gt 0 ]; then
  echo "[herdr:sync-machines] Added $added Tailscale machine(s) to Herdr"
fi
if [ "$failed" -gt 0 ]; then
  echo "[herdr:sync-machines] $failed machine(s) not added; retry with: herdr machine add <target>" >&2
fi
