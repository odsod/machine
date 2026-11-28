#!/usr/bin/env bash
# Install or upgrade odsod-daemon to a git ref, then let it install its
# services (odsod/daemon ADR-0006). Rerun to upgrade. A dev deploy at the same
# commit is replaced too: the installed source must be git.
set -euo pipefail

ref="${1:-main}"
url=https://github.com/odsod/daemon
step() { echo "[daemon:setup] $1"; }
fail() {
  echo "[daemon:setup] failed: $1. Rerun: mise run daemon:setup $ref" >&2
  exit 1
}

step "resolve $ref"
if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
  commit="$ref"
else
  commit="$(git ls-remote "$url" "$ref" | cut -f1)" || fail "git ls-remote (network?)"
  [ -n "$commit" ] || fail "unknown ref $ref"
fi

installed="$(odsodctl version --json 2>/dev/null | jq -r '"\(.source) \(.commit)"' || true)"
if [ "$installed" != "git $commit" ]; then
  step "uv tool install $commit"
  uv tool install --force --python "$DAEMON_PYTHON" \
    "odsod-daemon[bench] @ git+$url@$commit" || fail "uv tool install"
fi

# Linger keeps the user manager, and so the pipeline and retention timer,
# running after a logout.
step "linger"
loginctl enable-linger "$USER" || fail "loginctl enable-linger"

step "install --system"
sudo "$(command -v odsodctl)" install --system || fail "odsodctl install --system"

step "install"
odsodctl install || fail "odsodctl install"
