#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

force=0

while [ $# -gt 0 ]; do
  case "$1" in
  -f | --force)
    force=1
    shift
    ;;
  -h | --help)
    echo "Usage: mise run apply [OPTIONS]"
    echo
    echo "Apply every current version and config in the repo: full convergence."
    echo
    echo "Options:"
    echo "  -f, --force  Merge the antigravity repo keys into the live config and"
    echo "               overwrite the live codex config before convergence. The"
    echo "               codex overwrite drops private runtime state; the app"
    echo "               re-prompts for it."
    echo "  -h, --help   Show this help message"
    exit 0
    ;;
  -*)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

cd "$REPO_DIR"

if [ "$force" -eq 1 ]; then
  echo "[apply] Resolving codex and antigravity config drift"
  mise run codex:resolve
  mise run antigravity:resolve
fi

mise bootstrap --yes
mise reshim

echo "[apply] Cleaning old source trees and data..."
mise run clean
