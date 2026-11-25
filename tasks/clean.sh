#!/usr/bin/env bash
set -euo pipefail

# Delete tool versions no tracked config selects, and forget tracked configs
# whose files are gone (old workspaces). mise keeps versions a running process
# started from.
mise prune --yes

echo "[clean] Done"
