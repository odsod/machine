# KDE

## Fonts

- `fonts.conf` (`~/.config/fontconfig/conf.d/10-rendering.conf`) sets
  fontconfig rendering across all apps:
  - `rgba=none` and `lcdfilter=lcdnone`: grayscale antialiasing (Wayland
    windows scale and rotate, which breaks subpixel rendering).
  - `hintslight`: snaps stems to the pixel grid without distorting glyphs.
  - `embeddedbitmap=false`: forces outline rendering on high-DPI displays.
- `mise run kde:setup-fonts` sets Inter (UI) and Iosevka SS08 (monospace) in
  `~/.config/kdeglobals`.
- Verify rendering: `fc-match -v 'Inter' | rg 'rgba|lcdfilter|embeddedbitmap|hintstyle'`
- Verify KDE font: `kreadconfig6 --group "General" --key "font"`

## Colors

- `color-schemes/Nord.colors` is Breeze Dark with Nord palette values. The
  dotfile puts it in `~/.local/share/color-schemes/`.
- `mise run kde:setup-colors` applies the scheme and sets the accent color to
  Frost `#88C0D0`.
- The scheme covers Qt apps, Breeze decorations, and Plasma widget text and
  highlights. Breeze Plasma style SVGs, including the panel background, keep
  their own colors. GTK and browser themes are per app.

## Wallpaper

- `mise run kde:setup-wallpaper` downloads `ign-0011.png` from the Nordic
  wallpapers repo, verifies its SHA-256, installs it to
  `/usr/share/wallpapers/nordic-ign-0011.png`, sets it on every Plasma desktop,
  sets it on the lock screen, and points the Plasma Login Manager at it.
- The image URL is pinned to an upstream commit. Change the URL and checksum
  together.
- The lock screen reads `~/.config/kscreenlockerrc`. The Screen Locking KCM
  writes the same keys.
- The login screen reads `/etc/plasmalogin.conf`. The Login Screen KCM writes
  the same keys.

## KWallet

- `kwalletrc` enables KWallet without the first-use wizard so `pam-kwallet`
  auto-unlocks on login.
- If the wallet is missing, create it in `kwalletmanager6` with name
  `kdewallet`, Blowfish encryption, and the login password.
