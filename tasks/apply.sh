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
    echo "  -f, --force  Run every config resolve task before convergence. This"
    echo "               merges the antigravity repo keys into the live config and"
    echo "               overwrites the live codex config. The codex overwrite drops"
    echo "               private runtime state; the app re-prompts for it."
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
  mise run resolve
fi

echo "[apply] Checking config drift..."
if ! mise run config:check; then
  echo "[apply] Config drift blocks convergence." >&2
  echo "[apply] Copy wanted settings into the repo, then run: mise run resolve" >&2
  exit 1
fi

mise bootstrap --yes
mise reshim

echo "[apply] Cleaning old source trees and data..."
mise run clean
