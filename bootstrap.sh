#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a fresh machine from this repo.
#
# Prerequisites:
#   sudo dnf copr enable jdx/mise -y
#   sudo dnf install mise -y
#
# Then run:
#   ./bootstrap.sh

if ! command -v mise &>/dev/null; then
  echo "mise not found. Install via:"
  echo "  sudo dnf copr enable jdx/mise -y && sudo dnf install mise -y"
  exit 1
fi

mise trust
mise bootstrap --yes
