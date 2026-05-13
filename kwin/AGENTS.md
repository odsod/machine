# kwin

## Architecture

- **KWin script** (`contents/code/main.js`): Registers Meta+key shortcuts, toggles app windows by `resourceClass`/`resourceName`
- **DBus service** (`odsod-kwin-dbus-service.py`): Receives commands from KWin script, launches apps, logs debug output
- **Shortcut kinds**: `builtin` (KWin native), `app` (focus-or-launch), `command` (fire-and-forget), `callback` (inline JS)

## Development

- `make install-package && make enable-plugin`: Reload after editing `main.js`
- `make tail`: Stream debug logs from the DBus service
- `Meta+W`: Recorder note popup (`recorder-note` via kdialog)
- `Meta+;`: Debug shortcut — dumps all window `resourceName`/`resourceClass` to journal

## Chrome on Wayland: Window Class Rules

**CRITICAL**: Chrome's `--class` flag behavior differs between modes on Wayland.

| Launch mode         | `--class` respected? | Wayland `app_id` set to                          |
| ------------------- | -------------------- | ------------------------------------------------ |
| Normal (no `--app`) | **Yes**              | Value of `--class`                               |
| `--app=<url>`       | **No**               | `chrome-{url_host}__-{profile}` (auto-generated) |

- `--class` maps to X11 `WM_CLASS` but Chromium also routes it to Wayland `xdg_toplevel_set_app_id` — **only in non-app mode**
- In `--app` mode, Chromium overrides the app_id with a URL-derived value regardless of `--class`
- `--user-data-dir` does **not** affect the app_id

### Pattern: Chrome window with custom class

Use `--user-data-dir` (separate profile) + `--class=<Name>` **without** `--app`:

```sh
google-chrome --user-data-dir="$HOME/.local/share/path/to/profile" --class=MyApp "$URL"
```

- Gives a normal Chrome window (supports tabs)
- `resourceClass` in KWin matches the `--class` value
- Each `--user-data-dir` isolates cookies/history

### Pattern: Chrome --app mode (no class control)

For `--app` windows, match using `resourceClassIncludes` with the URL host:

```js
resourceClassIncludes: "meet.google.com"; // matches chrome-meet.google.com__-Default
```

- No tabs — single-page window
- Class is auto-generated, not controllable
