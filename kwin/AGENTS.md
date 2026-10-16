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
