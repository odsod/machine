# Keys Daemon

## Architecture

- `odsod-keys.c` compiles to `/usr/local/bin/odsod-keys` and runs as the root
  `odsod-keys.service` systemd unit.
- Grabs all physical keyboards via `EVIOCGRAB`, watches `/dev/input/` via
  `inotify` for hotplug, and writes remapped events to `/dev/uinput` (vendor/product
  `0x4f44:0x4b59`).

## Overload State Machine

- **`capslock` and `leftctrl` -> `Ctrl` / `Esc`**:
  - Press emits `Ctrl` down immediately.
  - Release within 250ms with no intervening key emits an `Esc` tap.
  - Release after an intervening key emits `Ctrl` up.
- **`space` -> `Meta` chord / `Space`** (`IDLE -> PENDING -> HELD`):
  - `PENDING` buffers events when space is pressed.
  - Another key held past 150ms or tapped within 150ms transitions to `HELD`
    and flushes the buffer as `Meta` chords.
  - Space released within 350ms emits `Space` and flushes buffered keys
    normally.
  - Space released after 350ms with no other key drops the tap.
- **Transient `Meta_L`**:
  - `odsod-keys` never holds `Meta_L` across a layer (`Meta_L down -> key down -> SYN -> key up -> Meta_L up -> SYN` per keystroke).
  - Sustaining `Meta_L` (as `keyd` does with `meta:M` and `inhibit_modifier_guard = 1`) causes KDE Plasma to see a bare `Meta_L` release and open the application launcher.

## Development

- Build and install: `mise run keys:build`
- Build, install, and restart service: `mise run keys:deploy`
- Follow logs: `mise run keys:log`
- Stop service (restores raw keyboard): `mise run keys:stop`
