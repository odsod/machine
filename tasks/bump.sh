#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

remote_url="$(git -C "$REPO_DIR" config --get remote.origin.url || true)"
REPO="$(printf '%s' "$remote_url" | sed 's#.*github\.com[:/]##; s#\.git$##')"
if [[ ! "$REPO" =~ ^[^/:]+/[^/]+$ ]]; then
  echo "Aborting: cannot read a GitHub owner/repo from remote.origin.url." >&2
  exit 1
fi

if ! open_prs="$(gh pr list --state open "--repo=$REPO" 2>&1)"; then
  echo "Aborting: cannot list open PRs on $REPO:" >&2
  # shellcheck disable=SC2001
  echo "$open_prs" | sed 's/^/  /' >&2
  exit 1
fi
if [ -n "$open_prs" ]; then
  echo "Aborting: unmerged PRs on $REPO:" >&2
  # shellcheck disable=SC2001
  echo "$open_prs" | sed 's/^/  /' >&2
  echo 'Merge or close them first. Rebase onto the fresh trunk, then rerun:' >&2
  echo '  jj git fetch --remote origin && jj rebase -o main@origin' >&2
  exit 1
fi

all=0
dry_run=0
no_apply=0
targets=()

while [ $# -gt 0 ]; do
  case "$1" in
  --all)
    all=1
    shift
    ;;
  -n | --dry-run)
    dry_run=1
    shift
    ;;
  --no-apply)
    no_apply=1
    shift
    ;;
  -h | --help)
    echo "Usage: mise run bump [OPTIONS] [TARGETS...]"
    echo
    echo "Options:"
    echo "  --all        Include GPU services (llama, whisper) that compile from source"
    echo "  -n, --dry-run Show what would be bumped without modifying files"
    echo "  --no-apply   Update files without running mise run apply"
    echo "  -h, --help   Show this help message"
    echo
    echo "Targets: yaak, obsidian, slack, zoom, cursor, soap-ui, endpoint-verification, llama, whisper"
    exit 0
    ;;
  -*)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  *)
    targets+=("$1")
    shift
    ;;
  esac
done

if [ ${#targets[@]} -eq 0 ]; then
  if [ "$all" -eq 1 ]; then
    targets=(yaak obsidian slack zoom cursor soap-ui endpoint-verification llama whisper)
  else
    targets=(yaak obsidian slack zoom cursor soap-ui endpoint-verification)
  fi
fi

gh_tag() {
  gh api "repos/$1/releases/latest" --jq '.tag_name' 2>/dev/null |
    grep -oP '^v?\K[0-9][0-9.]*$'
}

redirect_location() {
  curl -sI --max-time 20 "$1" 2>/dev/null | tr -d '\r' | grep -i '^location:' | tail -1
}

check_url() {
  local url="$1"
  curl -sI -f -L --max-time 15 "$url" >/dev/null 2>&1
}

changed_count=0
gpu_changed=0

bump_target() {
  local name="$1"
  local pinned=""
  local latest=""
  local check_target_url=""
  local is_gpu=0

  case "$name" in
  yaak)
    pinned="$(sed -n 's/^yaak_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    latest="$(gh_tag mountain-loop/yaak)"
    check_target_url="https://github.com/mountain-loop/yaak/releases/download/v${latest}/yaak-${latest}-1.x86_64.rpm"
    ;;
  obsidian)
    pinned="$(sed -n 's/^obsidian_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    latest="$(gh api 'repos/obsidianmd/obsidian-releases/releases?per_page=20' \
      --jq 'first(.[] | select([.assets[].name] | any(test("^Obsidian-[0-9.]+\\.AppImage$"))) | .tag_name)' 2>/dev/null |
      grep -oP '^v\K[0-9][0-9.]*$')"
    check_target_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${latest}/Obsidian-${latest}.AppImage"
    ;;
  slack)
    pinned="$(sed -n 's/^slack_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    latest="$(curl -s --max-time 20 https://slack.com/release-notes/linux/rss 2>/dev/null |
      grep -oP '<title>Slack \K[0-9][0-9.]*' | head -1)"
    check_target_url="https://downloads.slack-edge.com/desktop-releases/linux/x64/${latest}/slack-${latest}-0.1.el8.x86_64.rpm"
    ;;
  zoom)
    pinned="$(sed -n 's/^zoom_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    latest="$(redirect_location https://zoom.us/client/latest/zoom_x86_64.rpm |
      grep -oP '/prod/\K[0-9][0-9.]*')"
    check_target_url="https://zoom.us/client/${latest}/zoom_x86_64.rpm"
    ;;
  cursor)
    pinned="$(sed -n 's/^cursor_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    local cursor_loc
    cursor_loc="$(redirect_location https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest)"
    latest="$(echo "$cursor_loc" | grep -oP '/cursor-\K[0-9][0-9.]*(?=\.el8)')"
    local cursor_hash
    cursor_hash="$(echo "$cursor_loc" | grep -oP '/production/\K[0-9a-f]{40}')"
    if [ -n "$latest" ] && [ -n "$cursor_hash" ]; then
      check_target_url="https://downloads.cursor.com/production/${cursor_hash}/linux/x64/rpm/x86_64/cursor-${latest}.el8.x86_64.rpm"
    fi
    ;;
  soap-ui)
    pinned="$(sed -n 's/^soap_ui_version = "\(.*\)"$/\1/p' "$REPO_DIR/mise.toml")"
    latest="$(curl -sL --max-time 25 https://www.soapui.org/downloads/latest-release/ 2>/dev/null |
      grep -oP 'SoapUI-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    check_target_url="https://dl.eviware.com/soapuios/${latest}/SoapUI-${latest}-linux-bin.tar.gz"
    ;;
  endpoint-verification)
    pinned="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/endpoint-verification/mise.toml")"
    local ev_info
    ev_info="$(mise run -C "$REPO_DIR/endpoint-verification" --output interleave --quiet discover)"
    latest="$(echo "$ev_info" | sed -n 's/^version = "\(.*\)"$/\1/p')"
    local ev_deb
    ev_deb="$(echo "$ev_info" | sed -n 's/^deb = "\(.*\)"$/\1/p')"
    local ev_sha256
    ev_sha256="$(echo "$ev_info" | sed -n 's/^sha256 = "\(.*\)"$/\1/p')"
    if [ -n "$ev_deb" ]; then
      check_target_url="https://packages.cloud.google.com/apt/${ev_deb}"
    fi
    ;;
  llama)
    pinned="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/llama/mise.toml")"
    latest="$(mise run -C "$REPO_DIR/llama" --output interleave --quiet discover | tail -1)"
    check_target_url="https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${latest}.tar.gz"
    is_gpu=1
    ;;
  whisper)
    pinned="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/whisper/mise.toml")"
    latest="$(mise run -C "$REPO_DIR/whisper" --output interleave --quiet discover | tail -1)"
    check_target_url="https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v${latest}.tar.gz"
    is_gpu=1
    ;;
  *)
    echo "Unknown target: $name" >&2
    return 1
    ;;
  esac

  if [ -z "$latest" ] || [ "$latest" = "UNKNOWN" ]; then
    echo "[bump] $name: could not discover latest version" >&2
    return 1
  fi

  if [ "$pinned" = "$latest" ]; then
    echo "[bump] $name: $pinned is up to date"
    return 0
  fi

  if [ -n "$check_target_url" ]; then
    if ! check_url "$check_target_url"; then
      echo "[bump] $name: pre-flight check failed for $check_target_url" >&2
      return 1
    fi
  fi

  echo "[bump] $name: $pinned -> $latest"
  if [ "$dry_run" -eq 1 ]; then
    changed_count=$((changed_count + 1))
    return 0
  fi

  case "$name" in
  yaak)
    sed -i "s/^yaak_version = \".*\"/yaak_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    ;;
  obsidian)
    sed -i "s/^obsidian_version = \".*\"/obsidian_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    ;;
  slack)
    sed -i "s/^slack_version = \".*\"/slack_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    ;;
  zoom)
    sed -i "s/^zoom_version = \".*\"/zoom_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    ;;
  cursor)
    sed -i "s/^cursor_version = \".*\"/cursor_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    sed -i "s/^cursor_hash = \".*\"/cursor_hash = \"$cursor_hash\"/" "$REPO_DIR/mise.toml"
    ;;
  soap-ui)
    sed -i "s/^soap_ui_version = \".*\"/soap_ui_version = \"$latest\"/" "$REPO_DIR/mise.toml"
    ;;
  endpoint-verification)
    sed -i "s|^version = \".*\"|version = \"$latest\"|" "$REPO_DIR/endpoint-verification/mise.toml"
    sed -i "s|^deb = \".*\"|deb = \"$ev_deb\"|" "$REPO_DIR/endpoint-verification/mise.toml"
    sed -i "s|^sha256 = \".*\"|sha256 = \"$ev_sha256\"|" "$REPO_DIR/endpoint-verification/mise.toml"
    ;;
  llama)
    sed -i "s/^version = \".*\"/version = \"$latest\"/" "$REPO_DIR/llama/mise.toml"
    ;;
  whisper)
    sed -i "s/^version = \".*\"/version = \"$latest\"/" "$REPO_DIR/whisper/mise.toml"
    ;;
  esac

  changed_count=$((changed_count + 1))
  if [ "$is_gpu" -eq 1 ]; then
    gpu_changed=1
  fi
}

for target in "${targets[@]}"; do
  bump_target "$target"
done

if [ "$changed_count" -eq 0 ]; then
  echo "[bump] All targets up to date."
  exit 0
fi

if [ "$dry_run" -eq 1 ]; then
  echo "[bump] Dry run complete. $changed_count targets would be bumped."
  exit 0
fi

if [ "$no_apply" -eq 1 ]; then
  echo "[bump] Updated pins for $changed_count targets. Skipped apply."
  exit 0
fi

echo "[bump] Applying updates..."
mise run apply

if [ "$gpu_changed" -eq 1 ]; then
  echo "[bump] Restarting GPU user services..."
  systemctl --user restart llama-server whisper-server 2>/dev/null || true
fi

echo "[bump] Cleaning old source trees and data..."
mise run clean

echo "[bump] Verifying discovery..."
mise run discover
