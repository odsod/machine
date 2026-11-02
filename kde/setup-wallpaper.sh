#!/usr/bin/env bash
# Set the Nord wallpaper on Plasma, the lock screen, and the Plasma Login Manager.
set -euo pipefail

url="https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/af963c2531b1a4b7ec23fbff1779387950dfdbe9/wallpapers/ign-0011.png"
sha256="10598031eb1db1365c1026ba7f606425764a1fd7fbcb9306482e7c2fa1381270"
image="/usr/share/wallpapers/nordic-ign-0011.png"

if [ ! -f "$image" ] || ! echo "$sha256  $image" | sha256sum --check --status; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$url" -o "$tmp"
  echo "$sha256  $tmp" | sha256sum --check --status
  sudo install -Dm644 "$tmp" "$image"
fi

if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] &&
  command -v plasma-apply-wallpaperimage >/dev/null; then
  plasma-apply-wallpaperimage --fill-mode preserveAspectCrop "$image"
fi

if [ -f /etc/plasmalogin.conf ]; then
  sudo kwriteconfig6 --file /etc/plasmalogin.conf --group Greeter --key WallpaperPluginId org.kde.image
  sudo kwriteconfig6 --file /etc/plasmalogin.conf --group Greeter --key WallpaperPlugin org.kde.image
  sudo kwriteconfig6 --file /etc/plasmalogin.conf --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$image"
  sudo kwriteconfig6 --file /etc/plasmalogin.conf --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$image"
fi

kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$image"
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$image"
