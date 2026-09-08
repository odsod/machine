#!/usr/bin/env bash
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "[herdr:sync-machines] tailscale or jq not found; skipping"
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

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/herdr/client"
ENDPOINTS_FILE="$STATE_DIR/endpoints.json"
mkdir -p "$STATE_DIR"

existing_catalog='{"version":1,"ssh":[]}'
if [ -f "$ENDPOINTS_FILE" ]; then
  existing_catalog="$(cat "$ENDPOINTS_FILE" 2>/dev/null || echo '{"version":1,"ssh":[]}')"
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

new_ssh="[]"
count=0
for peer in $peers; do
  [ -n "$peer" ] || continue
  id="$(printf '%s' "$peer" | md5sum | cut -d' ' -f1)"

  existing_profile="$(printf '%s\n' "$existing_catalog" | jq --arg target "$peer" '.ssh[] | select(.target == $target)' 2>/dev/null || true)"

  if [ -n "$existing_profile" ]; then
    new_ssh="$(printf '%s\n' "$new_ssh" | jq --argjson profile "$existing_profile" '. + [$profile]')"
  else
    new_ssh="$(printf '%s\n' "$new_ssh" | jq \
      --arg id "$id" \
      --arg target "$peer" \
      --arg label "$peer" \
      '. + [{id: $id, label: $label, target: $target, session: "default", enabled: true}]')"
  fi
  count=$((count + 1))
done

final_catalog="$(jq -n --argjson ssh "$new_ssh" '{version: 1, ssh: $ssh}')"

current_content=""
if [ -f "$ENDPOINTS_FILE" ]; then
  current_content="$(cat "$ENDPOINTS_FILE" 2>/dev/null || true)"
fi

if [ "$current_content" != "$final_catalog" ]; then
  temp_file="$(mktemp "$STATE_DIR/endpoints.XXXXXX")"
  chmod 600 "$temp_file"
  printf '%s\n' "$final_catalog" > "$temp_file"
  mv "$temp_file" "$ENDPOINTS_FILE"
  echo "[herdr:sync-machines] Synced $count Tailscale machine(s) to Herdr catalog"
fi
