# kwin

Custom KWin script and companion DBus service for window management.

## Components

### KWin Script (`contents/code/main.js`)

Plasma KWin plugin (`metadata.json`) that:

- **App shortcuts**: `Meta+<key>` to focus-or-launch apps. Toggles minimize if already focused.
- **Built-in rebinds**: Remaps default KWin actions (tiling, close, maximize, expose).
- **No-border**: Removes titlebar/frame from selected apps via `noBorder` flag.

### DBus Service (`odsod-kwin-dbus-service.py`)

User-space Python service (`io.github.odsod.kwin`) auto-activated via D-Bus. Bridges
KWin's sandboxed JS environment to the session:

- **`run_shortcut`**: Launches apps via `subprocess.Popen`.
- **`configure_shortcuts`**: Binds/unbinds global shortcuts via `KGlobalAccel`. Cleans up stale `[odsod]` shortcuts on reload.
- **`log`**: Forwards script logs to syslog (`journalctl --user -t odsod-kwin-dbus-service`).
