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

dry_run=0
targets=()

while [ $# -gt 0 ]; do
  case "$1" in
  -n | --dry-run)
    dry_run=1
    shift
    ;;
  -h | --help)
    echo "Usage: mise run bump [OPTIONS] [TARGETS...]"
    echo
    echo "Upgrades [tools] and bumps every self-managed pin."
    echo "Run: mise run apply"
    echo
    echo "Options:"
    echo "  -n, --dry-run  Preview bumps without changing files"
    echo "  -h, --help     Show this help message"
    echo
    echo "Targets: neovim, yaak, obsidian, slack, zoom, cursor, soap-ui, endpoint-verification, llama, whisper"
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

# No targets means a full bump: every pin, including the GPU services, the
# Neovim plugin lock, and the mise-managed [tools]. An explicit target bumps
# only that pin.
tools=1
if [ ${#targets[@]} -gt 0 ]; then
  tools=0
else
  targets=(neovim yaak obsidian slack zoom cursor soap-ui endpoint-verification llama whisper)
fi

# 1. mise-managed tools. `--bump` moves the runtime major prefixes too, which is
# the point of a full bump. GITHUB_TOKEN keeps `mise lock` from dropping
# platforms under GitHub rate limits.
tools_changed=0
if [ "$tools" -eq 1 ]; then
  export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token 2>/dev/null || true)}"
  if [ "$dry_run" -eq 1 ]; then
    echo "[bump] Tools that would be upgraded:"
    mise upgrade --bump --dry-run -x http:obsidian -x http:soap-ui
  else
    before="$(git -C "$REPO_DIR" hash-object mise.lock mise.toml)"
    echo "[bump] Upgrading mise tools..."
    # http:obsidian and http:soap-ui pin a concrete version from [vars] and have
    # no version_list_url, so mise cannot list their releases. Skip their upgrade
    # check: the pins loop below owns both.
    (cd "$REPO_DIR" && mise upgrade --bump -x http:obsidian -x http:soap-ui)
    after="$(git -C "$REPO_DIR" hash-object mise.lock mise.toml)"
    [ "$before" = "$after" ] || tools_changed=1
  fi
fi

# Self-managed pins live in topic fragments under mise/conf.d/. Return the file
# that defines the named pin.
pin_file() {
  case "$1" in
  slack | zoom | yaak | soap-ui | obsidian | cursor | llama | whisper | endpoint-verification)
    echo "$REPO_DIR/mise/conf.d/$1.toml"
    ;;
  *)
    echo "Unknown pin: $1" >&2
    return 1
    ;;
  esac
}

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

# Print the plugins whose lockfile revision is behind the remote default
# branch, one "name old -> new" line each. The dry run must not touch the
# lockfile, so it compares revisions instead of calling vim.pack.update. Lock
# entries with no "version" track the remote default branch, so HEAD is the
# target; entries with a "version" track a tag or branch and are left alone. A
# probe that fails prints a warning and makes the function fail.
neovim_pack_stale() {
  python3 - "$REPO_DIR/neovim/nvim-pack-lock.json" <<'PY'
import json, subprocess, sys

stale = []
failed = False
for name, spec in sorted(json.load(open(sys.argv[1]))["plugins"].items()):
    if "version" in spec:
        continue
    proc = subprocess.run(
        ["git", "ls-remote", spec["src"], "HEAD"],
        capture_output=True, text=True,
    )
    remote = proc.stdout.split()[0] if proc.stdout.strip() else ""
    if not remote:
        print(f"  {name}: cannot read remote HEAD", file=sys.stderr)
        failed = True
    elif remote != spec["rev"]:
        stale.append(f"  {name}: {spec['rev'][:12]} -> {remote[:12]}")
print("\n".join(stale))
sys.exit(1 if failed else 0)
PY
}

bump_neovim() {
  local lock="$REPO_DIR/neovim/nvim-pack-lock.json"

  if [ "$dry_run" -eq 1 ]; then
    local stale
    stale="$(neovim_pack_stale)" || true
    if [ -z "$stale" ]; then
      echo "[bump] neovim: plugins up to date"
    else
      echo "[bump] neovim: plugins would update:"
      printf '%s\n' "$stale"
      changed_count=$((changed_count + 1))
    fi
    return 0
  fi

  local before after
  before="$(git -C "$REPO_DIR" hash-object "$lock")"
  echo "[bump] Updating Neovim plugins..."
  # require('odsod.pack').update() updates every plugin and then syncs the
  # lockfile from the actual checkouts, including a checkout already ahead of
  # a stale lockfile, which plain vim.pack.update() leaves behind. Wrap it in
  # pcall because a headless Lua error exits 0.
  nvim --headless '+lua local ok, err = pcall(require("odsod.pack").update); if not ok then vim.api.nvim_err_writeln(err); vim.cmd("cquit 1") end' +qa
  after="$(git -C "$REPO_DIR" hash-object "$lock")"
  if [ "$before" = "$after" ]; then
    echo "[bump] neovim: plugins up to date"
  else
    echo "[bump] neovim: pack lock updated"
    changed_count=$((changed_count + 1))
  fi
}

changed_count=0

bump_target() {
  local name="$1"
  if [ "$name" = neovim ]; then
    bump_neovim
    return 0
  fi
  local pinned=""
  local latest=""
  local check_target_url=""

  case "$name" in
  yaak)
    pinned="$(sed -n 's/^yaak_version = "\(.*\)"$/\1/p' "$(pin_file yaak)")"
    latest="$(gh_tag mountain-loop/yaak)"
    check_target_url="https://github.com/mountain-loop/yaak/releases/download/v${latest}/yaak-${latest}-1.x86_64.rpm"
    ;;
  obsidian)
    pinned="$(sed -n 's/^obsidian_version = "\(.*\)"$/\1/p' "$(pin_file obsidian)")"
    latest="$(gh api 'repos/obsidianmd/obsidian-releases/releases?per_page=20' \
      --jq 'first(.[] | select([.assets[].name] | any(test("^Obsidian-[0-9.]+\\.AppImage$"))) | .tag_name)' 2>/dev/null |
      grep -oP '^v\K[0-9][0-9.]*$')"
    check_target_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${latest}/Obsidian-${latest}.AppImage"
    ;;
  slack)
    pinned="$(sed -n 's/^slack_version = "\(.*\)"$/\1/p' "$(pin_file slack)")"
    latest="$(curl -s --max-time 20 https://slack.com/release-notes/linux/rss 2>/dev/null |
      grep -oP '<title>Slack \K[0-9][0-9.]*' | head -1)"
    check_target_url="https://downloads.slack-edge.com/desktop-releases/linux/x64/${latest}/slack-${latest}-0.1.el8.x86_64.rpm"
    ;;
  zoom)
    pinned="$(sed -n 's/^zoom_version = "\(.*\)"$/\1/p' "$(pin_file zoom)")"
    latest="$(redirect_location https://zoom.us/client/latest/zoom_x86_64.rpm |
      grep -oP '/prod/\K[0-9][0-9.]*')"
    check_target_url="https://zoom.us/client/${latest}/zoom_x86_64.rpm"
    ;;
  cursor)
    pinned="$(sed -n 's/^cursor_version = "\(.*\)"$/\1/p' "$(pin_file cursor)")"
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
    pinned="$(sed -n 's/^soap_ui_version = "\(.*\)"$/\1/p' "$(pin_file soap-ui)")"
    latest="$(curl -sL --max-time 25 https://www.soapui.org/downloads/latest-release/ 2>/dev/null |
      grep -oP 'SoapUI-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    check_target_url="https://dl.eviware.com/soapuios/${latest}/SoapUI-${latest}-linux-bin.tar.gz"
    ;;
  endpoint-verification)
    pinned="$(sed -n 's/^endpoint_verification_version = "\(.*\)"$/\1/p' "$(pin_file endpoint-verification)")"
    local ev_info
    ev_info="$(mise run --output interleave --quiet endpoint-verification:discover)"
    latest="$(echo "$ev_info" | sed -n 's/^endpoint_verification_version = "\(.*\)"$/\1/p')"
    local ev_deb
    ev_deb="$(echo "$ev_info" | sed -n 's/^endpoint_verification_deb = "\(.*\)"$/\1/p')"
    local ev_sha256
    ev_sha256="$(echo "$ev_info" | sed -n 's/^endpoint_verification_sha256 = "\(.*\)"$/\1/p')"
    if [ -n "$ev_deb" ]; then
      check_target_url="https://packages.cloud.google.com/apt/${ev_deb}"
    fi
    ;;
  llama)
    pinned="$(sed -n 's/^llama_version = "\(.*\)"$/\1/p' "$(pin_file llama)")"
    latest="$(mise run --output interleave --quiet llama:discover | tail -1)"
    check_target_url="https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${latest}.tar.gz"
    ;;
  whisper)
    pinned="$(sed -n 's/^whisper_version = "\(.*\)"$/\1/p' "$(pin_file whisper)")"
    latest="$(mise run --output interleave --quiet whisper:discover | tail -1)"
    check_target_url="https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v${latest}.tar.gz"
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
    sed -i "s/^yaak_version = \".*\"/yaak_version = \"$latest\"/" "$(pin_file yaak)"
    ;;
  obsidian)
    sed -i "s/^obsidian_version = \".*\"/obsidian_version = \"$latest\"/" "$(pin_file obsidian)"
    ;;
  slack)
    sed -i "s/^slack_version = \".*\"/slack_version = \"$latest\"/" "$(pin_file slack)"
    ;;
  zoom)
    sed -i "s/^zoom_version = \".*\"/zoom_version = \"$latest\"/" "$(pin_file zoom)"
    ;;
  cursor)
    sed -i "s/^cursor_version = \".*\"/cursor_version = \"$latest\"/" "$(pin_file cursor)"
    sed -i "s/^cursor_hash = \".*\"/cursor_hash = \"$cursor_hash\"/" "$(pin_file cursor)"
    ;;
  soap-ui)
    sed -i "s/^soap_ui_version = \".*\"/soap_ui_version = \"$latest\"/" "$(pin_file soap-ui)"
    ;;
  endpoint-verification)
    sed -i "s|^endpoint_verification_version = \".*\"|endpoint_verification_version = \"$latest\"|" "$(pin_file endpoint-verification)"
    sed -i "s|^endpoint_verification_deb = \".*\"|endpoint_verification_deb = \"$ev_deb\"|" "$(pin_file endpoint-verification)"
    sed -i "s|^endpoint_verification_sha256 = \".*\"|endpoint_verification_sha256 = \"$ev_sha256\"|" "$(pin_file endpoint-verification)"
    ;;
  llama)
    sed -i "s/^llama_version = \".*\"/llama_version = \"$latest\"/" "$(pin_file llama)"
    ;;
  whisper)
    sed -i "s/^whisper_version = \".*\"/whisper_version = \"$latest\"/" "$(pin_file whisper)"
    ;;
  esac

  changed_count=$((changed_count + 1))
}

for target in "${targets[@]}"; do
  bump_target "$target"
done

if [ "$dry_run" -eq 1 ]; then
  echo "[bump] Dry run complete. $changed_count targets would be bumped."
  exit 0
fi

if [ "$changed_count" -eq 0 ] && [ "$tools_changed" -eq 0 ]; then
  echo "[bump] Everything up to date."
  exit 0
fi

echo "[bump] Formatting configs..."
(cd "$REPO_DIR" && mise fmt --all)

echo "[bump] Verifying discovery..."
mise run discover

echo "[bump] Versions bumped. Run: mise run apply"
