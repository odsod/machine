#!/bin/bash
# Fetch the current official icons for the Chrome app windows into icons/.
# Google, Discord, and Linear grant no free license for these marks; the files
# are vendored here for personal use only.
# Refresh everything with: mise run google-chrome:icons
set -euo pipefail

GEN="${CHROME_ICON_GENERATION:?CHROME_ICON_GENERATION is not set}"
DEST="$(dirname "$(readlink -f "$0")")/icons"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Fail loudly instead of vendoring an HTML error page.
check_svg() {
  grep -q '<svg' "$1" || {
    echo "[google-chrome] $2 is not an SVG" >&2
    exit 1
  }
}

# Give an SVG an explicit viewBox, taken from width/height when the file has
# none. With mode "square", also pad it to a square canvas with an 8% margin,
# so a wide mark sits at the same visual weight as the square product logos.
fix_svg() {
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys

src, dst, mode = sys.argv[1:4]
text = open(src, encoding="utf-8").read()
match = re.search(r'viewBox="([-\d.]+) ([-\d.]+) ([-\d.]+) ([-\d.]+)"', text)
if match:
    box = [float(v) for v in match.groups()]
else:
    size = re.search(r'<svg[^>]*\bwidth="([\d.]+)"[^>]*\bheight="([\d.]+)"', text)
    if not size:
        sys.exit(f"{src}: no viewBox and no width/height")
    box = [0.0, 0.0, *(float(v) for v in size.groups())]
x, y, w, h = box
if mode == "square":
    side = max(w, h) * 1.16
    box = [x - (side - w) / 2, y - (side - h) / 2, side, side]

if match and box == [float(v) for v in match.groups()]:
    out = text
elif match:
    out = text[: match.start()] + f'viewBox="{" ".join(f"{v:.3f}" for v in box)}"' + text[match.end() :]
else:
    tag = f'<svg viewBox="{" ".join(f"{v:.3f}" for v in box)}"'
    out = re.sub(r"<svg\b", lambda _: tag, text, count=1)
open(dst, "w", encoding="utf-8").write(out)
PY
}

# Google Workspace product logos, already on a square canvas. Google moves the
# generation token in these paths after a redesign, so a 404 here means the pin
# in mise/conf.d/google-chrome.toml needs a bump.
google() {
  local product="$1" name="$2" url
  url="https://www.gstatic.com/images/branding/productlogos/${product}_${GEN}/web/192px.svg"
  curl -fsSL --max-time 30 "$url" -o "$WORK/$name.svg" || {
    echo "[google-chrome] No icon at $url" >&2
    echo "[google-chrome] Google moved the generation. Bump vars.chrome_icon_generation." >&2
    exit 1
  }
  check_svg "$WORK/$name.svg" "$url"
  fix_svg "$WORK/$name.svg" "$DEST/$name.svg" viewbox
  echo "[google-chrome] $name.svg <- $url"
}

# Discord's official symbol is a wide mark, so it needs the square canvas.
# The asset URL carries a content hash and stays fixed.
discord() {
  local zip="https://cdn.discordapp.com/assets/content/a736b95923ddbc155e828651c92471292e40727655d770a06cec89c48ba0b41f.zip"
  curl -fsSL --max-time 60 "$zip" -o "$WORK/discord.zip"
  unzip -p "$WORK/discord.zip" 'Discord_Symbol_Color/Discord-Symbol-Blurple.svg' \
    >"$WORK/discord.svg"
  check_svg "$WORK/discord.svg" discord
  fix_svg "$WORK/discord.svg" "$DEST/discord.svg" square
  echo "[google-chrome] discord.svg <- $zip"
}

# Linear's brand kit ships the app icon (gradient tile, white mark) on a square
# canvas. The plain mark is either near-black or white, so it disappears on one
# of the Plasma themes.
linear() {
  local zip="https://static.linear.app/design-assets/Linear-Brand-Assets.zip"
  curl -fsSL --max-time 120 "$zip" -o "$WORK/linear.zip"
  unzip -p "$WORK/linear.zip" linear-icon.svg >"$WORK/linear.svg"
  check_svg "$WORK/linear.svg" linear
  fix_svg "$WORK/linear.svg" "$DEST/linear.svg" viewbox
  echo "[google-chrome] linear.svg <- $zip"
}

google gmail gmail
google calendar google-calendar
google meet google-meet
discord
linear

chmod 644 "$DEST"/*.svg
