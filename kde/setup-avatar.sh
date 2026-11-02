#!/usr/bin/env bash
# Set the account profile image from Gravatar through accountsservice.
set -euo pipefail

url="https://gravatar.com/avatar/ee423260241ee5bd76e415bf8c6cb69b?s=512"
sha256="b77b1b1e4c5b80d197f196fa2d93a78d32b53051665e333dc04cc31ff0cc0951"
user="odsod"
bus="org.freedesktop.Accounts"
uid="$(id -u "$user")"
path="/org/freedesktop/Accounts/User$uid"
icon="/var/lib/AccountsService/icons/$user"

icon_file="$(busctl get-property "$bus" "$path" "$bus.User" IconFile | cut -d '"' -f2)"
if [ "$icon_file" = "$icon" ] && [ -r "$icon" ] &&
  echo "$sha256  $icon" | sha256sum --check --status; then
  echo "Profile image already set."
  exit 0
fi

tmp="$(mktemp --suffix=.png)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp"
echo "$sha256  $tmp" | sha256sum --check --status
busctl call "$bus" "$path" "$bus.User" SetIconFile s "$tmp"

# accountsservice emits the change before the copy completes. Wait for it.
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if [ -r "$icon" ] && echo "$sha256  $icon" | sha256sum --check --status; then
    exit 0
  fi
  sleep 0.2
done
echo "Icon did not appear at $icon" >&2
exit 1
