#!/usr/bin/env bash
# Give frameless windows a server-side shadow, outline, and rounded corners.
# Plasma 6.8 and later: "shadow" selects a shadow-only KDecoration style.
set -euo pipefail

rules=(ghostty chrome-apps slack spotify keepassxc obsidian)

write_rule() {
  local id=$1 description=$2 wmclass=$3 wmclassmatch=$4

  kwriteconfig6 --file kwinrulesrc --group "$id" --key Description "$description"
  kwriteconfig6 --file kwinrulesrc --group "$id" --key decorationpolicy shadow
  kwriteconfig6 --file kwinrulesrc --group "$id" --key decorationpolicyrule 2
  kwriteconfig6 --file kwinrulesrc --group "$id" --key types 1
  kwriteconfig6 --file kwinrulesrc --group "$id" --key wmclass "$wmclass"
  kwriteconfig6 --file kwinrulesrc --group "$id" --key wmclasscomplete false
  kwriteconfig6 --file kwinrulesrc --group "$id" --key wmclassmatch "$wmclassmatch"
}

# Ghostty draws no frame. Chrome app windows are frameless xdg_toplevels whose
# app_id is chrome-<host>__-<profile>. Slack is X11 and already runs without a
# frame through the odsod KWin script. Spotify is a Flatpak that draws its own
# UI but still gets a Breeze titlebar. KeePassXC (Qt) and Obsidian (Electron)
# also get a Breeze titlebar that covers their own chrome.
write_rule ghostty "Window settings for ghostty" com.mitchellh.ghostty 1
write_rule chrome-apps "Window settings for Chrome app windows" '^chrome-.*__-' 3
write_rule slack "Window settings for Slack" slack 1
write_rule spotify "Window settings for Spotify" com.spotify.Client 1
write_rule keepassxc "Window settings for KeePassXC" org.keepassxc.KeePassXC 1
write_rule obsidian "Window settings for Obsidian" md.obsidian.Obsidian 1

# Keep existing rules and their order. KWin 6.8 reads General/Order, older
# versions read General/rules, so write both.
current=$(kreadconfig6 --file kwinrulesrc --group General --key Order)
ordered=()
IFS=',' read -r -a existing <<<"$current"
for id in "${existing[@]}"; do
  if [[ -z $id ]]; then
    continue
  fi
  if [[ " ${rules[*]} " == *" $id "* ]]; then
    continue
  fi
  ordered+=("$id")
done
ordered+=("${rules[@]}")
list=$(
  IFS=','
  echo "${ordered[*]}"
)
kwriteconfig6 --file kwinrulesrc --group General --key Order "$list"
kwriteconfig6 --file kwinrulesrc --group General --key rules "$list"

qdbus-qt6 org.kde.KWin /KWin reconfigure
