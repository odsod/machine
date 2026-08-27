#!/usr/bin/env bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# mise reads GITHUB_TOKEN; gh reads the keyring. Without this bridge `mise
# outdated` runs unauthenticated and GitHub rate-limits most tool lookups.
if [ -z "${GITHUB_TOKEN:-}" ]; then
  token="$(gh auth token 2>/dev/null)"
  if [ -n "$token" ]; then
    export GITHUB_TOKEN="$token"
  else
    echo "warning: gh is not logged in; mise outdated may be rate-limited" >&2
  fi
fi

rows=""

# A probe that matches nothing prints UNKNOWN rather than a partial match, so a
# changed upstream release scheme shows up as a gap instead of a wrong version.
row() {
  local name="$1" pinned="$2" latest="${3:-}" status
  if [ -z "$latest" ]; then
    latest="UNKNOWN"
    status="?"
  elif [ "$pinned" = "$latest" ]; then
    status="ok"
  else
    status="BUMP"
  fi
  rows="${rows}${name}\t${pinned}\t${latest}\t${status}\n"
}

gh_tag() {
  gh api "repos/$1/releases/latest" --jq '.tag_name' 2>/dev/null \
    | grep -oP '^v?\K[0-9][0-9.]*$'
}

redirect_location() {
  curl -sI --max-time 20 "$1" 2>/dev/null | tr -d '\r' | grep -i '^location:' | tail -1
}

cursor_location="$(redirect_location https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest)"

nested_discover() {
  MISE_TASK_OUTPUT=quiet mise run -C "$REPO_DIR/$1" discover 2>/dev/null
}

pinned_var() {
  sed -n 's/^version = "\(.*\)"$/\1/p' "$REPO_DIR/$1/mise.toml"
}

row inter "$PINNED_INTER" "$(gh_tag rsms/inter)"
row iosevka "$PINNED_IOSEVKA" "$(gh_tag be5invis/Iosevka)"
row nerd-fonts "$PINNED_NERD_FONTS" "$(gh_tag ryanoasis/nerd-fonts)"
row yaak "$PINNED_YAAK" "$(gh_tag mountain-loop/yaak)"

# The newest Obsidian tag is sometimes Android only, so take the newest release
# that actually ships a desktop AppImage.
row obsidian "$PINNED_OBSIDIAN" "$(
  gh api 'repos/obsidianmd/obsidian-releases/releases?per_page=20' \
    --jq 'first(.[] | select([.assets[].name] | any(test("^Obsidian-[0-9.]+\\.AppImage$"))) | .tag_name)' 2>/dev/null \
    | grep -oP '^v\K[0-9][0-9.]*$'
)"

row slack "$PINNED_SLACK" "$(
  curl -s --max-time 20 https://slack.com/release-notes/linux/rss 2>/dev/null \
    | grep -oP '<title>Slack \K[0-9][0-9.]*' | head -1
)"

row zoom "$PINNED_ZOOM" "$(
  redirect_location https://zoom.us/client/latest/zoom_x86_64.rpm \
    | grep -oP '/prod/\K[0-9][0-9.]*'
)"

row cursor "$PINNED_CURSOR" "$(echo "$cursor_location" | grep -oP '/cursor-\K[0-9][0-9.]*(?=\.el8)')"
row cursor-hash "$PINNED_CURSOR_HASH" "$(echo "$cursor_location" | grep -oP '/production/\K[0-9a-f]{40}')"

row soap-ui "$PINNED_SOAP_UI" "$(
  curl -sL --max-time 25 https://www.soapui.org/downloads/latest-release/ 2>/dev/null \
    | grep -oP 'SoapUI-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1
)"

row llama "$(pinned_var llama)" "$(nested_discover llama | tail -1)"
row whisper "$(pinned_var whisper)" "$(nested_discover whisper | tail -1)"
row endpoint-verification "$(pinned_var endpoint-verification)" \
  "$(nested_discover endpoint-verification | sed -n 's/^version = "\(.*\)"$/\1/p')"

printf 'NAME\tPINNED\tLATEST\tSTATUS\n%b' "$rows" | column -t -s "$(printf '\t')"

echo
echo "Pins for fonts and desktop apps live in [vars] in mise.toml."
echo "llama, whisper, and endpoint-verification pin in their own mise.toml."
echo "Paste-ready endpoint-verification pins: mise run -C endpoint-verification discover"
echo
echo "--- mise tools ---"
mise outdated
