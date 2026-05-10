# odsod-keys

Custom keyboard remapper for Linux. Replaces [keyd](https://github.com/rvaiya/keyd)
with a purpose-built ~500 line C daemon that does exactly three things:

1. **esc ↔ capslock** — swap escape and capslock
2. **capslock/leftctrl** — tap: escape, hold: control
3. **space** — tap: space, hold: meta modifier (per-keystroke, never sustained)

## Why not keyd?

keyd's built-in `meta` layer emits a physical `Meta_L` keypress that KDE
interprets as "open application launcher" on release. This is unfixable from
config — it's a fundamental interaction between keyd's modifier guard logic and
KDE's modifier-only shortcut detection. See `AGENTS.md` for the full analysis.

## Install

```bash
make -C keys
```

## Usage

```bash
make -C keys deploy    # rebuild + install + restart
make -C keys restart   # restart without rebuild
make -C keys stop      # stop (restores raw keyboard)
make -C keys log       # tail service logs
make -C keys status    # check service state
make -C keys uninstall # remove binary + service
```

## Tuning

Constants in `odsod-keys.c`:

| Constant | Default | Purpose |
|----------|---------|---------|
| `HOLD_THRESHOLD_NS` | 150ms | Min hold time before keypress resolves as Meta combo |
| `TAP_TIMEOUT_NS` | 350ms | Max press duration to register as space tap |
