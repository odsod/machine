# keys Agent Guide

## Scope

- Path: `keys/`
- Binary: `/usr/local/bin/odsod-keys`
- Service: `odsod-keys.service` (systemd, root)
- Source: single file `odsod-keys.c`

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────────┐
│ Physical KBD(s) │────▶│  odsod-keys  │────▶│ uinput virtual kbd  │
│ /dev/input/eventN│     │  (event loop)│     │ (remapped output)   │
└─────────────────┘     └──────────────┘     └─────────────────────┘
      EVIOCGRAB              poll()              write(uinput_fd)
   (exclusive grab)
```

- Grabs all physical keyboards exclusively via `EVIOCGRAB`
- Creates a virtual keyboard via `/dev/uinput`
- Processes events in a `poll()` loop
- Hotplug: `inotify` on `/dev/input/` for new devices
- Identifies own virtual device by vendor/product `0x4f44:0x4b59`

## State Machine

Three independent overload handlers:

### capslock / leftctrl → ctrl/esc

Simple overload:
- Press → emit `Ctrl down` immediately
- Release < 250ms with no intervening key → emit `Esc` tap
- Release after intervening key → just `Ctrl up`

### space → meta-layer/space

Three-state machine: `IDLE → PENDING → HELD`

```
PENDING: space pressed, buffering events
  ├── another key pressed (> 150ms) → HELD, flush queue as Meta chords
  ├── another key tapped (press+release < 150ms) → HELD, flush as Meta
  ├── space released (< 350ms) → emit space + flush queue as normal keys
  └── space released (> 350ms) → drop everything (accidental hold)

HELD: meta layer active
  └── all subsequent keys emit as Meta+key until space released
```

### Critical design decision: Meta_L is never sustained

Unlike keyd's `:M` layer modifier (which holds `Meta_L` for the duration
of the layer activation), this daemon emits Meta only transiently per
keystroke:

```
Meta_L down → key down → SYN → key up → Meta_L up → SYN
```

This makes it impossible for KDE to see a bare `Meta_L` tap, eliminating
the application launcher trigger entirely.

## Key constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `HOLD_THRESHOLD_NS` | 150ms | Rollover protection window |
| `TAP_TIMEOUT_NS` | 350ms | Max duration for space tap |
| `MAX_QUEUE` | 16 | Event buffer during PENDING state |
| `MAX_DEVICES` | 32 | Maximum simultaneous keyboards |

## Development workflow

```bash
make -C keys build     # compile only (verify)
make -C keys deploy    # build + install + restart service
make -C keys log       # tail journalctl output
make -C keys stop      # stop service (raw keyboard restored)
```

After editing `odsod-keys.c`, run `make -C keys deploy` to test changes.
If the keyboard becomes unresponsive, the service can be stopped via SSH
or from another machine.

## Upstream references

- [keyd](https://github.com/rvaiya/keyd) — original inspiration, modifier
  guard analysis from `src/keyboard.c`
- [Linux input subsystem](https://www.kernel.org/doc/html/latest/input/input.html)
  — `EV_KEY`, `EV_SYN`, key repeat (`value=2`)
- [uinput](https://www.kernel.org/doc/html/latest/input/uinput.html) —
  virtual device creation
- [evdev](https://www.freedesktop.org/software/libevdev/doc/latest/) —
  event codes reference (`linux/input-event-codes.h`)

## Background: keyd Meta + KDE interaction

The reason this daemon exists (migrated from keyd v2.6.0):

1. keyd's `meta` layer is internally `meta:M` — activating it emits
   `Meta_L down` immediately
2. On release without intervening keypress, keyd's `OP_LAYER` handler
   sets `inhibit_modifier_guard = 1` (line 625 in `src/keyboard.c`)
3. This disables the Ctrl interposition guard that normally prevents
   DEs from seeing bare modifier taps
4. KDE Plasma sees `Meta_L down → Meta_L up` → fires application launcher
5. Neither `[ModifierOnlyShortcuts] Meta=` in kwinrc nor removing Meta
   from plasmashell's kglobalaccel binding fully prevents this

The fix is architectural: never emit a sustained `Meta_L` keypress.
