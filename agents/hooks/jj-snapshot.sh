#!/usr/bin/env bash
set -euo pipefail

if [ -d .jj ]; then
  jj st >/dev/null 2>&1 || true
  exit 0
fi

if [ ! -t 0 ]; then
  dir="$(jq -r '.workspacePaths[0] // .cwd // empty' 2>/dev/null || true)"
  if [ -n "$dir" ] && [ -d "$dir/.jj" ]; then
    jj -R "$dir" st >/dev/null 2>&1 || true
  fi
fi
