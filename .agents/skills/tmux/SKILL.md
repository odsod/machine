---
name: tmux
description: >
  Deep expertise for configuring and theming tmux. Use when writing or editing
  ~/.config/tmux/tmux.conf or any tmux configuration, including: status bar
  content and styling, window/pane border themes, colour schemes, format
  strings, option configuration, key bindings, hooks, and mouse support.
  Covers the full tmux option system (server/session/window/pane scopes),
  the complete style/colour syntax, and the format variable system.
---

# tmux Skill

## Reference Files

Read these before working on specific topics:

- **[references/theming.md](references/theming.md)** — Style syntax, colour specification,
  all text attributes, every themeable option by area (status bar, panes, borders, menus,
  copy mode), inline style embedding, light/dark theme hooks, common patterns
- **[references/configuration.md](references/configuration.md)** — Config file locations,
  option scopes and `set-option` syntax, all server/session/window/pane options,
  hooks system, key bindings, mouse support
- **[references/formats.md](references/formats.md)** — All `#{...}` variables (session,
  window, pane, client, mouse, etc.), every modifier and operator (conditionals, comparisons,
  numeric ops, truncation, padding, loops, substitution), shell command integration

The raw man page is at `references/man/tmux.1` and source at `references/tmux/`.

---

## Quick Reference

### Config Location

```
~/.tmux.conf  OR  $XDG_CONFIG_HOME/tmux/tmux.conf
```

### Option Scopes

```bash
set -g   option value    # global session option
set -wg  option value    # global window option
set -s   option value    # server option
set -p   option value    # pane option
# tmux infers scope from option name; -g covers most cases
```

### Style Syntax

```
fg=colour,bg=colour,bold,italics,reverse,dim,underscore,...
```

Colours: `black` `red` `green` `yellow` `blue` `magenta` `cyan` `white`,
`brightblack`…`brightwhite`, `colour0`–`colour255`, `#rrggbb`, `default`, `terminal`,
plus full X11 colour names (e.g., `DeepSkyBlue4`, `MediumOrchid3`).

### Format Variables

```
#{session_name} #{window_name} #{window_index} #{window_flags}
#{pane_index} #{pane_title} #{pane_current_path} #{pane_current_command}
#{host} #{host_short}
```

Short aliases: `#S` `#W` `#I` `#F` `#P` `#T` `#H` `#h` `#D`

Shell output: `#(command)` — tmux caches; not synchronous.

Inline style: `#[fg=colour,bg=colour,bold]text#[default]`

### Reload Config

```bash
tmux source-file ~/.tmux.conf
# or bind to a key:
bind r source-file ~/.tmux.conf \; display "Reloaded"
```

### Debug / Inspect

```bash
tmux show -g                   # all global session options
tmux show -wg                  # all global window options
tmux show -s                   # all server options
tmux display -p '#{pane_id}'   # evaluate format in current pane
tmux display -pa               # list all format variables and values
```

---

## Key Architecture Facts

### Option Inheritance Chain
```
global session → session
global window  → window → pane
```
Setting `pane-border-style` globally (`set -wg`) affects all windows;
setting per-window (`set -w -t mywin`) overrides for that window only.

### Two Ways to Style Status Bar

1. **Option styles** (`status-style`, `window-status-current-style`, etc.) — base colours
2. **Inline `#[...]`** in format strings (`status-left`, `window-status-format`) — dynamic

They combine: inline styles override/layer on top of option styles.

### Status Bar Architecture

```
status-format[0] (default row):
  ┌─ status-left ─────────┬─ window list (list=on) ─────┬─ status-right ─┐
  │  styled by             │  window-status-format        │ styled by      │
  │  status-left-style     │  window-status-current-format│ status-right-  │
  │                        │  styled by -style options    │ style          │
  └────────────────────────┴──────────────────────────────┴────────────────┘
```

Full control: override `status-format[0]` entirely with custom layout using
`list=on`, `align=`, `range=`, `fill=` style markers.

### Window Flags

In `#{window_flags}` / `#F`:

| Flag | Meaning |
|------|---------|
| `*` | current window |
| `-` | last window |
| `#` | activity detected |
| `!` | bell occurred |
| `~` | silence alert |
| `M` | marked pane |
| `Z` | zoomed |

### True Colour Setup

```bash
set -g default-terminal "tmux-256color"
set -ga terminal-features ",*:RGB"
# or equivalently:
set -ga terminal-overrides ",*:Tc"
```

---

## Common Tasks

### Minimal Coloured Theme

```bash
set -g status-style                 "bg=colour235,fg=colour243"
set -g window-status-style          "bg=colour235,fg=colour243"
set -g window-status-current-style  "bg=colour166,fg=colour234,bold"
set -g window-status-format         " #I #W#F "
set -g window-status-current-format " #I #W#F "
set -g pane-border-style            "fg=colour238"
set -g pane-active-border-style     "fg=colour166"
set -g message-style                "bg=colour166,fg=colour234,bold"
set -g status-left                  " [#S] "
set -g status-right                 " %H:%M %d-%b "
```

### Inactive Pane Dimming

```bash
set -g window-style        "fg=colour243,bg=colour234"
set -g window-active-style "fg=colour252,bg=colour232"
```

### Dynamic Status Based on Pane State

```bash
# Turn status-left red when prefix is active:
set -g status-left "#{?client_prefix,#[bg=red],#[bg=blue]} #S "
# Show copy mode indicator:
set -g status-right "#{?pane_in_mode,COPY,} %H:%M"
```

### Automatic Light/Dark Theme

```bash
set-hook -g client-dark-theme  "source ~/.config/tmux/dark.conf"
set-hook -g client-light-theme "source ~/.config/tmux/light.conf"
```

### Pane Border with Title

```bash
set -g pane-border-status top
set -g pane-border-format " #{pane_index}: #{pane_current_command} #{pane_current_path} "
set -g pane-border-style        "fg=colour238"
set -g pane-active-border-style "fg=colour75"
```
