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

## KWallet

- `kwalletrc` enables KWallet without the first-use wizard so `pam-kwallet`
  auto-unlocks on login.
- If the wallet is missing, create it in `kwalletmanager6` with name
  `kdewallet`, Blowfish encryption, and the login password.
