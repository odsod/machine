# KDE

## Fonts

- `fonts.conf` (`~/.config/fontconfig/conf.d/10-rendering.conf`) sets
  fontconfig rendering across all apps:
  - `rgba=none` and `lcdfilter=lcdnone`: grayscale antialiasing (Wayland
    windows scale and rotate, which breaks subpixel rendering).
  - `hintslight`: snaps stems to the pixel grid without distorting glyphs.
  - `embeddedbitmap=false`: forces outline rendering on high-DPI displays.
- `mise run kde:setup-fonts` installs `fonts.conf` at
  `~/.config/fontconfig/conf.d/10-rendering.conf`, then sets Inter (UI) and
  Iosevka SS08 (monospace) in `~/.config/kdeglobals`.
- KDE writes that rendering file itself when font settings change, so the file
  is task-managed, not a dotfile symlink. A symlink there gets replaced by a
  plain file and `mise bootstrap` then refuses to overwrite it.
- Verify rendering: `fc-match -v 'Inter' | rg 'rgba|lcdfilter|embeddedbitmap|hintstyle'`
- Verify KDE font: `kreadconfig6 --group "General" --key "font"`

## Colors

- `color-schemes/Nord.colors` is Breeze Dark with Nord palette values. The
  dotfile puts it in `~/.local/share/color-schemes/`.
- `mise run kde:setup-colors` applies the scheme. It sets no accent color.
- The Plasma accent tint replaces the selection colors with a lightened accent
  and black text, because KDE picks black whenever white fails 4.5:1. Black on
  that mid-blue reads badly. Frost `#88C0D0` stays in the scheme as the focus
  and hover color, and selection keeps nord10 `#5E81AC` with the light text
  `#ECEFF4`.
- `plasma-apply-colorscheme` does nothing when the scheme is already current.
  The task deletes `General/ColorScheme` first to force a full write, which
  also clears an old accent block from `~/.config/kdeglobals`.
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

## Profile image

- `mise run kde:setup-avatar` downloads the Gravatar avatar of
  `oscardsoderlund`, verifies its SHA-256, and sets it through accountsservice.
  It needs no sudo.
- accountsservice `SetIconFile` writes `/var/lib/AccountsService/icons/odsod`
  and sets `Icon=` in `/var/lib/AccountsService/users/odsod`.
- The URL is pinned to the avatar hash from
  `https://gravatar.com/oscardsoderlund.json` (`photos[0].value`). Change the
  URL and checksum together after you change the Gravatar image.
- The image shows in Kickoff, System Settings Users, and the lock screen.
- accountsservice emits the icon change before it finishes the copy. A running
  Plasma Shell or System Settings can therefore cache a failed decode and keep
  showing no picture. Restart them
  (`systemctl --user restart plasma-plasmashell`), or log out and in.
- Verify:
  `busctl get-property org.freedesktop.Accounts /org/freedesktop/Accounts/User1000 org.freedesktop.Accounts.User IconFile`

## KWallet

- `kwalletrc` enables KWallet without the first-use wizard so `pam-kwallet`
  auto-unlocks on login.
- If the wallet is missing, create it in `kwalletmanager6` with name
  `kdewallet`, Blowfish encryption, and the login password.
