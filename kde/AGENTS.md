# kde/

KDE Plasma desktop configuration.

## Managed Config

| File            | Target                            | Purpose                                                         |
| --------------- | --------------------------------- | --------------------------------------------------------------- |
| `mimeapps.list` | `~/.config/mimeapps.list`         | Default app associations                                        |
| `fonts.conf`    | `~/.config/fontconfig/fonts.conf` | Font rendering (grayscale AA, no subpixel, no embedded bitmaps) |

## Font Configuration

Two layers:

- **`fonts.conf`** — fontconfig rules applied to all apps (GTK, Qt, Firefox, etc.)
- **`configure-fonts` target** — KDE-specific font selection via `kwriteconfig6` (writes to `~/.config/kdeglobals`)

### Design Decisions

- **`rgba=none` + `lcdfilter=lcdnone`**: Subpixel rendering is broken on Wayland (windows can rotate/scale arbitrarily). Grayscale antialiasing is correct.
- **`hintslight`**: Best tradeoff — snaps stems to pixel grid without distorting glyph shapes.
- **`embeddedbitmap=false`**: Bitmaps look terrible on high-DPI; forces outline rendering for all fonts.
- **Font families**: Inter (UI), Iosevka SS08 (monospace) — installed by `inter/` and `iosevka/` modules.

### Verifying

```bash
# Check effective rendering for a font
fc-match -v 'Inter' | rg 'rgba|lcdfilter|embeddedbitmap|hintstyle'

# Check KDE font selection
kreadconfig6 --group "General" --key "font"
```

## KWallet

Enables KWallet + PAM auto-unlock (no password prompt on login).
