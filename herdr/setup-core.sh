#!/usr/bin/env bash
# Point hc and herdr-core in ~/.local/bin at the pinned herdr-core, and say when
# a running core is older. The Herdr app finds herdr-core in ~/.local/bin before
# the mise shims, and its "Update herdr-core" button writes a plain file there:
# relinking replaces that file. Run from apply, not postinstall, so an install
# of an older pin from another workspace cannot move the links.
set -euo pipefail

log() { echo "[herdr:setup-core] $*"; }

bin="$(mise where http:herdr-core)/herdr-core"
for name in hc herdr-core; do
  link="$HOME/.local/bin/$name"
  if [ "$(readlink "$link" 2>/dev/null)" != "$bin" ]; then
    ln -fsT "$bin" "$link"
    log "Linked $name to $bin"
  fi
done

# `hc server status` starts a core when none runs, so look for one first.
if ! pgrep -u "$(id -u)" -f '(herdr-core|/hc) serve$' >/dev/null; then
  exit 0
fi
want="$("$bin" --version | awk '{print $2}')"
have="$(hc server status --json | jq -r '.version')"
# Restart by hand at a safe point: attached streams end and must reattach.
if [ "$have" != "$want" ]; then
  log "Core $have is running, $want is pinned. At a safe point: hc server restart"
fi

# A core started from an agent's shell keeps that agent's variables, and every
# terminal it starts inherits them: Claude then stops saving transcripts.
# `hc server restart` keeps them too; only a stop and a start from a clean
# shell clear them.
for pid in $(pgrep -u "$(id -u)" -f '(herdr-core|/hc) serve$'); do
  if tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | grep -qE '^(CLAUDECODE|CLAUDE_CODE_CHILD_SESSION)='; then
    log "Core $pid runs with Claude Code variables. At a safe point, from a shell outside Herdr: hc server stop && hc server start"
  fi
done
