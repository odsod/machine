# KWin

## Architecture

- **`contents/code/main.js`**: KWin script that binds `Meta+<key>` shortcuts,
  toggles app windows by `resourceClass` or `resourceName`, remaps window
  actions, and sets `noBorder`.
- **`odsod-kwin-dbus-service.py`**: User D-Bus service (`io.github.odsod.kwin`)
  that launches apps, registers global shortcuts in `KGlobalAccel`, and
  forwards script logs to the journal.
- **Shortcut kinds**: `builtin` (KWin action), `app` (focus or launch),
  `command` (fire and forget), `callback` (inline JS).

## Development

- Full install and reload: `mise run kwin:install`
- Reload after editing `main.js`: `mise run kwin:install-package && mise run kwin:enable-plugin`
- Tail D-Bus logs: `mise run kwin:tail`
- Dump all open window classes to the journal: `Meta+;`

## Chrome Window Classes on Wayland

- **Normal mode (no `--app`)**: Chromium passes `--class=<Name>` to Wayland
  `xdg_toplevel_set_app_id`. Pair `--user-data-dir` with `--class` to get an
  isolated profile with a controllable `resourceClass`:
  `google-chrome --user-data-dir="$HOME/.local/share/..." --class=MyApp "$URL"`
- **`--app=<url>` mode**: Chromium ignores `--class` and sets the Wayland
  `app_id` to `chrome-<host>__-<profile>`. Match these windows in `main.js`
  with `resourceClassIncludes: "<host>"`.

## Chrome Window Icons

KWin reports the `app_id` as the window's desktop file name, so Plasma resolves
icon and app name from a desktop file with the same basename. Without one the
window falls back to the generic Wayland icon.

- `google-chrome/applications/` holds one entry per app window, linked into
  `~/.local/share/applications/` by `[dotfiles]` in
  `mise/conf.d/google-chrome.toml`.
- Name each file `chrome-<host>__-Default.desktop` so it matches the app_id.
  Keep its `Exec=` in sync with the launch command in `main.js`. Write paths
  in full: desktop files do not expand `$HOME`.
- `Icon=` is `odsod-chrome-<name>`, from the brand-colored marks in
  `google-chrome/icons/`, linked into the user hicolor theme. Their `viewBox`
  adds a 12% margin on every side, so they match the visual weight of the
  package icons next to them. This is only for windows that would otherwise
  have no icon; every other app keeps the icon from Breeze or its own package.
- Plasma keeps app data for open windows, so windows that already exist before
  the first run need a plasmashell restart or a reopen to show the icon.

## Window Rules

`window-rules.sh` writes `~/.config/kwinrulesrc` rules that select the Plasma
6.8 shadow-only decoration (`decorationpolicy=shadow`): drop shadow, outline,
and rounded corners, with no titlebar. Run `mise run kwin:window-rules`, or
`mise run kwin:install` to run it with the rest of the KWin setup.

- `ghostty`: exact `wmclass` match on `com.mitchellh.ghostty`.
- `chrome-apps`: regex `wmclass` match on `^chrome-.*__-`. This covers every
  Chrome app window and not the normal browser window (`google-chrome`).
- `slack`: exact `wmclass` match on `slack`. Slack is an X11 window; the rule
  wins over the `noBorder` flag that `main.js` sets for it.
- `spotify`: exact `wmclass` match on `com.spotify.Client` (Flatpak). This drops
  the Breeze titlebar that Spotify would otherwise get.
- `keepassxc`: exact `wmclass` match on `org.keepassxc.KeePassXC`. The Qt app
  loses the Breeze titlebar; close it with `Meta+Backspace` or the menu.
- `obsidian`: exact `wmclass` match on `md.obsidian.Obsidian`. Obsidian keeps
  its own custom frame and window buttons.
- `herdr-app`: exact `wmclass` match on `herdr-app`, the Wayland `app_id` the
  app sets for itself. The layout draws its own titlebar (`titlebar: none`).

The radius, outline, and shadow size come from the Breeze decoration settings.
A decoration plugin must list the `shadow` style in its metadata.
