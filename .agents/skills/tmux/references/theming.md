# tmux Theming Reference

## Table of Contents
1. [Style Syntax](#style-syntax)
2. [Colour Specification](#colour-specification)
3. [Text Attributes](#text-attributes)
4. [Advanced Style Properties](#advanced-style-properties)
5. [All Themeable Options](#all-themeable-options)
6. [Inline Styles in Formats](#inline-styles-in-formats)
7. [Light/Dark Theme Hooks](#lightdark-theme-hooks)

---

## Style Syntax

A style is a **comma- or space-separated list** of properties. Order matters for override
semantics — later properties overwrite earlier ones.

```
set -g status-style "fg=colour235,bg=colour238,bold"
set -g status-style "bg=black fg=white"   # space separator also valid
```

The single word `default` resets to the inherited default style.

### Style Properties Quick Reference

| Property | Values | Notes |
|----------|--------|-------|
| `fg=colour` | see Colours | foreground text colour |
| `bg=colour` | see Colours | background colour |
| `us=colour` | see Colours | underscore colour |
| `fill=colour` | see Colours | fills remaining space in status sections |
| `none` | — | clears all attributes (fg/bg unaffected) |
| `noattr` | — | don't inherit attributes from default style |
| `align=left` | — | align text left (default) |
| `align=centre` | — | align text to centre |
| `align=right` | — | align text right |
| `align=absolute-centre` | — | centre relative to full terminal width |
| `width=N` | integer | fixed width (used for scrollbar width) |
| `pad=N` | integer | padding between element and adjacent content |
| `list=on` | — | marks start of window list in `status-format` |
| `list=focus` | — | the current-window part of the list |
| `list=left-marker` | — | text shown when list is trimmed on left |
| `list=right-marker` | — | text shown when list is trimmed on right |
| `nolist` | — | removes list marker |
| `range=left` | — | mouse range triggering `StatusLeft` key |
| `range=right` | — | mouse range triggering `StatusRight` key |
| `range=session\|X` | session-id | mouse range for specific session |
| `range=window\|X` | window-index | mouse range for specific window |
| `range=pane\|X` | pane-id | mouse range for specific pane |
| `range=user\|X` | string ≤15 bytes | user-defined mouse range |
| `norange` | — | removes range marker |
| `push-default` | — | saves current colours/attrs as new default |
| `pop-default` | — | restores previous saved default |
| `set-default` | — | sets current as default (non-reversible) |
| `ignore` | — | ignore this style when applying |
| `noignore` | — | stop ignoring |

---

## Colour Specification

### Named Basic Colours (8)
```
black  red  green  yellow  blue  magenta  cyan  white
```

### Bright Variants (8)
```
brightblack   brightred   brightgreen   brightyellow
brightblue    brightmagenta  brightcyan  brightwhite
```

### Special Values
```
default    # inherit from parent/default style
terminal   # terminal's own default colour
```

### 256-Colour Palette
```
colour0 to colour255    # xterm 256-colour palette
color0  to color255     # American spelling also accepted
```

Structure of the 256-colour palette:
- **0–7**: standard colours (matches named colours above)
- **8–15**: bright colours (matches bright variants above)
- **16–231**: 6×6×6 RGB colour cube
  - Formula: `16 + 36*r + 6*g + b` where r,g,b ∈ 0..5
  - Values map to: 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff
- **232–255**: 24-step greyscale (from dark to light)
  - Values: 0x08, 0x12, 0x1c, 0x26, 0x30, 0x3a, 0x44, 0x4e, ...

### 24-bit RGB (True Colour)
```
#rrggbb    # hex notation, e.g. #1e1e2e, #cdd6f4
```
Requires terminal with RGB/true-colour support. Enable with:
```
set -g terminal-features "*:RGB"
# or
set -ga terminal-overrides ",*:Tc"
```

### X11 Named Colours
Full X11 colour database supported. Examples:
```
AliceBlue  AntiqueWhite  Aquamarine  Azure  Bisque
CadetBlue  Chartreuse  Chocolate  Coral  Cornflower
DarkBlue  DarkCyan  DarkGoldenrod  DarkGreen  DarkGray
DeepPink  DeepSkyBlue  DodgerBlue  FireBrick  ForestGreen
Gold  Goldenrod  HotPink  IndianRed  Khaki
LavenderBlush  LawnGreen  LightBlue  LightCoral  LightCyan
MediumOrchid  MediumPurple  MidnightBlue  MintCream
NavajoWhite  OliveDrab  OrangeRed  Orchid  PeachPuff
RebeccaPurple  RosyBrown  RoyalBlue  SaddleBrown  Salmon
SeaGreen  SkyBlue  SlateBlue  SlateGray  SpringGreen
SteelBlue  Tan  Teal  Thistle  Tomato  Turquoise  Violet
WebGray  WhiteSmoke  YellowGreen
```
Also: `grey0`–`grey100` and `gray0`–`gray100` (maps `grey50` → `#808080`).

---

## Text Attributes

All attributes can be prefixed with `no` to disable: `nobold`, `noitalics`, etc.

| Attribute | Alias | Description |
|-----------|-------|-------------|
| `bright` | `bold` | bold / bright text |
| `dim` | — | dim/faint text |
| `underscore` | — | single underline |
| `double-underscore` | — | double underline |
| `curly-underscore` | — | curly/wavy underline |
| `dotted-underscore` | — | dotted underline |
| `dashed-underscore` | — | dashed underline |
| `blink` | — | blinking text |
| `reverse` | — | reverse video (fg/bg swap) |
| `hidden` | — | invisible text |
| `italics` | — | italic text |
| `strikethrough` | — | strikethrough |
| `overline` | — | overline |
| `acs` | — | alternate character set (box drawing) |
| `noattr` | — | do not inherit attributes from default |
| `none` | — | clear ALL attributes |

Note: `double-underscore`, `curly-underscore`, `dotted-underscore`, `dashed-underscore`,
`overline`, and `strikethrough` require terminal support (check `terminal-features`).

---

## Advanced Style Properties

### `fill=colour`
Fills empty space in a status section with the given background colour. Different from `bg=`:
- `bg=` colours the text cell backgrounds
- `fill=` colours the remaining empty area after content

```
set -g status-left-style "bg=blue,fill=colour237"
```

### `align=`
Controls text alignment within a fixed-width section:
```
set -g status-left "#[align=centre]#{session_name}"
```

### `list=` markers
Used in `status-format[]` to define window list regions:
```
# In status-format, mark where window list starts and ends:
set -g status-format[0] "#[list=on,align=centre]..."
```

### `range=` for mouse
Mark clickable regions in status bar. The `Status` key binding is triggered on click:
```
# In status-format, create a clickable session indicator:
"#[range=session|#{session_id}]#{session_name}#[norange]"
```

### `push-default` / `pop-default`
Save and restore style context within a format string:
```
"#[push-default,bg=blue,fg=white]active#[pop-default]normal"
```

### `set-default`
Permanently change what `default` means for subsequent style references in this format.

---

## All Themeable Options

### Status Bar (Session Options)

| Option | Default | Description |
|--------|---------|-------------|
| `status` | `on` | `off`/`on`/`2`/`3`/`4`/`5` — show status, optionally multi-line |
| `status-style` | `default` | base style for entire status line |
| `status-left` | `[#S] ` | left section content (format string) |
| `status-left-length` | `10` | max chars for left section |
| `status-left-style` | `default` | style for left section |
| `status-right` | `"#T" %H:%M %d-%b-%y` | right section content |
| `status-right-length` | `40` | max chars for right section |
| `status-right-style` | `default` | style for right section |
| `status-format[]` | (complex default) | full control of each status line row |
| `status-position` | `bottom` | `top` or `bottom` |
| `status-justify` | `left` | `left`/`centre`/`right`/`absolute-centre` |
| `status-interval` | `15` | refresh interval in seconds |

### Window List (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `window-status-format` | `#I:#W#F` | format for inactive windows |
| `window-status-current-format` | `#I:#W#F` | format for current window |
| `window-status-style` | `default` | style for inactive windows |
| `window-status-current-style` | `default` | style for current window |
| `window-status-last-style` | `default` | style for last-active window |
| `window-status-activity-style` | `default` | style when window has activity |
| `window-status-bell-style` | `default` | style when window has bell |
| `window-status-separator` | ` ` | string between window entries |

### Pane Borders (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `pane-border-style` | `default` | inactive pane border style |
| `pane-active-border-style` | `fg=green` | active pane border style |
| `pane-border-lines` | `single` | `single`/`double`/`heavy`/`simple`/`number`/`spaces` |
| `pane-border-indicators` | `colour` | `off`/`colour`/`arrows`/`both` |
| `pane-border-status` | `off` | `off`/`top`/`bottom` — show pane title in border |
| `pane-border-format` | `#P: #T` | format for pane border title |

### Pane Background (Pane Options)

| Option | Default | Description |
|--------|---------|-------------|
| `window-style` | `default` | style for inactive panes (bg/fg of pane content) |
| `window-active-style` | `default` | style for the active pane |
| `pane-colours[]` | — | override terminal colour palette (indices 0–255) |
| `cursor-colour` | `default` | pane cursor colour |
| `cursor-style` | `default` | `default`/`blinking-block`/`block`/`blinking-underline`/`underline`/`blinking-bar`/`bar` |

### Pane Scrollbars (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `pane-scrollbars` | `off` | `off`/`modal`/`on` |
| `pane-scrollbars-style` | — | `fg=` slider, `bg=` bar, `width=` width, `pad=` padding |
| `pane-scrollbars-position` | `right` | `left`/`right` |

### Pane Status Line (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `pane-status-style` | `default` | style for pane border status |
| `pane-status-current-style` | `default` | style for active pane border status |
| `session-status-style` | `default` | style per session in status |
| `session-status-current-style` | `default` | style for current session in status |

### Messages & Prompts (Session Options)

| Option | Default | Description |
|--------|---------|-------------|
| `message-style` | `bg=yellow,fg=black` | style for status line messages |
| `message-command-style` | `bg=black,fg=yellow` | style for vi command mode |
| `message-line` | `0` | status line row for messages (0–4) |
| `display-panes-colour` | `blue` | colour for inactive pane indicators |
| `display-panes-active-colour` | `red` | colour for active pane indicator |

### Menus (Session Options)

| Option | Default | Description |
|--------|---------|-------------|
| `menu-style` | `default` | style for menu content |
| `menu-selected-style` | `bg=yellow,fg=black` | style for selected menu item |
| `menu-border-style` | `default` | style for menu border |
| `menu-border-lines` | `single` | border line type |

### Popups (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `popup-style` | `default` | style for popup content |
| `popup-border-style` | `default` | style for popup border |
| `popup-border-lines` | `single` | `single`/`rounded`/`double`/`heavy`/`simple`/`padded`/`none` |

### Copy Mode (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `mode-style` | `bg=yellow,fg=black` | general mode indicator style |
| `copy-mode-selection-style` | `bg=white,fg=black` | selected text style |
| `copy-mode-match-style` | `bg=cyan,fg=black` | search matches style |
| `copy-mode-current-match-style` | `bg=orange,fg=black` | current search match style |
| `copy-mode-mark-style` | `bg=red,fg=default` | line containing mark |
| `copy-mode-position-style` | `default` | position indicator style |

### Clock (Window Options)

| Option | Default | Description |
|--------|---------|-------------|
| `clock-mode-colour` | `green` | clock face colour |
| `clock-mode-style` | `24` | `12`/`24`/`12-with-seconds`/`24-with-seconds` |

---

## Inline Styles in Formats

Within any format string (status-left, window-status-format, etc.), embed styles using:
```
#[style-spec]
```

Multiple properties: `#[fg=red,bg=black,bold]`

Reset to inherited: `#[default]`

### Inline Style Examples

```bash
# Status left: session name in bold blue, with separator
set -g status-left "#[fg=blue,bold] #S #[fg=default,nobold]│"

# Window format: index in dim, name bold when active
set -g window-status-format         "#[dim]#I #[nodim]#W#[fg=yellow]#F"
set -g window-status-current-format "#[bold,fg=white]#I #W#[fg=yellow]#F#[nobold]"

# Conditional inline style based on pane mode:
set -g window-status-format "#{?pane_in_mode,#[bg=red],#[bg=default]}#W"

# Separator with powerline-style triangles:
set -g window-status-separator ""
set -g window-status-format         "#[fg=colour237,bg=colour239] #W #[fg=colour239,bg=colour237]"
set -g window-status-current-format "#[fg=colour237,bg=colour75] #W #[fg=colour75,bg=colour237]"
```

### Style Stacking
Styles stack: each `#[...]` block adds to the current style rather than replacing it.
- `#[fg=red]text#[bold]more` → "text" is red, "more" is red+bold
- `#[default]` resets to the option's base style (e.g., `window-status-style`)
- `#[none]` clears attributes but not fg/bg

---

## Light/Dark Theme Hooks

tmux detects terminal background theme changes and fires hooks:

```bash
# React to theme changes automatically
set-hook -g client-dark-theme  "source ~/.config/tmux/dark.conf"
set-hook -g client-light-theme "source ~/.config/tmux/light.conf"
```

tmux determines light/dark by the terminal background colour:
- RGB brightness sum > 382 (of 765 max) → light
- RGB brightness sum ≤ 382 → dark
- Named `white`/`brightwhite` → light
- Named `black`/`brightblack` → dark

### Conditional Config by Host

```bash
%if "#{==:#{host},myhost}"
set -g status-style "bg=colour22"
%elif "#{==:#{host},server1}"
set -g status-style "bg=colour52"
%else
set -g status-style "bg=colour18"
%endif
```

---

## Common Theme Patterns

### Minimal Two-Colour Status

```bash
set -g status-style                 "bg=colour234,fg=colour137"
set -g window-status-format         " #I:#W#F "
set -g window-status-current-format " #I:#W#F "
set -g window-status-current-style  "bg=colour166,fg=colour234,bold"
set -g window-status-style          "bg=colour234,fg=colour137"
set -g pane-border-style            "fg=colour238"
set -g pane-active-border-style     "fg=colour166"
set -g message-style                "bg=colour166,fg=colour234,bold"
```

### Powerline-Style (requires Nerd Font or powerline font)

```bash
# Left section: session block
set -g status-left "#[fg=colour232,bg=colour166,bold] #S #[fg=colour166,bg=colour238] #[fg=colour245,bg=colour238] #(whoami) #[fg=colour238,bg=colour234]"
set -g status-left-length 30
set -g status-left-style default

# Window list separators use triangle characters
set -g window-status-separator ""
set -g window-status-format         "#[fg=colour237,bg=colour234]#[fg=colour245,bg=colour237] #W #[fg=colour237,bg=colour234]"
set -g window-status-current-format "#[fg=colour234,bg=colour166]#[fg=colour232,bg=colour166,bold] #W #[fg=colour166,bg=colour234]"
```

### Inactive Pane Dimming

```bash
set -g window-style        "fg=colour243,bg=colour234"
set -g window-active-style "fg=colour252,bg=colour232"
```

### Pane Border with Status

```bash
set -g pane-border-status top
set -g pane-border-format "#{?pane_active,#[bold],}#[fg=colour250] #{pane_index}: #{pane_current_command} #[fg=colour244]#{pane_current_path}"
set -g pane-border-style        "fg=colour238"
set -g pane-active-border-style "fg=colour166,bold"
```

### Pane Colour Palette Override

Override specific terminal colours for all panes:
```bash
# Override colour0 (black) to a slightly lighter shade:
set -g pane-colours[0] "#1e1e2e"
# Override colour15 (white):
set -g pane-colours[15] "#cdd6f4"
```
