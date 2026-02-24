# tmux Configuration Reference

## Table of Contents
1. [Config File Locations](#config-file-locations)
2. [Option Scopes & Commands](#option-scopes--commands)
3. [Config File Syntax](#config-file-syntax)
4. [Server Options](#server-options)
5. [Session Options](#session-options)
6. [Window Options](#window-options)
7. [Pane Options](#pane-options)
8. [Hooks](#hooks)
9. [Key Bindings](#key-bindings)
10. [Mouse Support](#mouse-support)

---

## Config File Locations

tmux loads in order:
1. `/etc/tmux.conf` (system-wide)
2. `~/.tmux.conf` OR `$XDG_CONFIG_HOME/tmux/tmux.conf`

Override with `-f file` flag at startup.

Reload at runtime: `source-file ~/.tmux.conf` (bind to a key with `bind r source-file ~/.tmux.conf \; display "reloaded"`).

---

## Option Scopes & Commands

### Scopes

| Scope | Flag | Description |
|-------|------|-------------|
| Server | `-s` | Global server settings (not per-session/window) |
| Global session | `-g` | Default for all sessions |
| Session | (default) | Per-session (inherits from global session) |
| Global window | `-wg` | Default for all windows |
| Window | `-w` | Per-window (inherits from global window) |
| Pane | `-p` | Per-pane (inherits from window) |

### `set-option` (alias: `set`)

```
set-option [-aFgopqsuUw] [-t target-pane] option [value]
```

| Flag | Effect |
|------|--------|
| `-g` | global (session or window depending on option) |
| `-s` | server option |
| `-w` | window option |
| `-p` | pane option |
| `-a` | append to existing value (strings and styles) |
| `-F` | expand formats in value |
| `-u` | unset option (reverts to inherited value) |
| `-U` | unset option on pane AND all panes in window |
| `-o` | only set if not already set |
| `-q` | suppress errors for unknown/ambiguous options |

tmux infers scope from option name (no need to specify `-w`/`-s` for known options):
```bash
set -g status on          # session option
set -g pane-border-style "fg=blue"  # window option (tmux infers -w)
set -g escape-time 0      # server option (tmux infers -s)
```

### `show-options` (alias: `show`)

```
show-options [-AgHpqsvw] [-t target-pane] [option]
```

| Flag | Effect |
|------|--------|
| `-g` | global options |
| `-s` | server options |
| `-w` | window options |
| `-p` | pane options |
| `-v` | value only (no option name) |
| `-A` | include inherited options (marked with `*`) |
| `-H` | include hooks |

### Array Options

Some options are arrays (`option[]`). Set individual elements:
```bash
set -g status-format[0] "..."
set -g status-format[1] "..."
set -s command-alias[0] "zoom=resize-pane -Z"
```

### User Options

Prefix with `@`. May have any name, string values only:
```bash
set -wq @my-option "value"
show -wv @my-option
```

---

## Config File Syntax

### Comments
```
# This is a comment
```

### Line Continuation
```
set -g status-left \
    "#[fg=blue]#S"
```

### Command Separation
```bash
new-window; new-window    # semicolon as separator
new-window \; new-window  # escaped semicolon in shell
```

### Quoting
```bash
set -g status-left "#{session_name}"   # double quotes: expand $VAR, formats
set -g status-left '#{session_name}'   # single quotes: literal
set -g status-left {                   # braces: multi-line, format-expanded
    #{session_name}
}
```

### Conditionals in Config
```bash
%if "#{==:#{host},hostname1}"
set -g status-style "bg=red"
%elif "#{==:#{host},hostname2}"
set -g status-style "bg=green"
%else
set -g status-style "bg=blue"
%endif
```

### Environment Variables
```bash
set -g status-left "$HOME"   # expands to home directory value
HOME=/different/path         # set env var during parsing
%hidden MYVAR=secret         # hidden var (not passed to child processes)
```

---

## Server Options

Set with `set -s` or `set-option -s`. Display with `show -s`.

| Option | Default | Description |
|--------|---------|-------------|
| `backspace` | `C-h` | key sent for backspace |
| `buffer-limit` | `50` | max number of paste buffers |
| `command-alias[]` | — | custom command aliases: `name=value` |
| `codepoint-widths[]` | — | override Unicode codepoint widths |
| `copy-command` | — | shell command to pipe copy-pipe output to |
| `default-client-command` | `new-session` | command run when tmux started without args |
| `default-terminal` | `screen` | TERM for new windows (must be screen/tmux derivative) |
| `escape-time` | `500` | milliseconds to wait after ESC for key sequences |
| `editor` | `$EDITOR` | editor command |
| `exit-empty` | `on` | exit server when no sessions remain |
| `exit-unattached` | `off` | exit server when no clients attached |
| `extended-keys` | `off` | `on`/`off`/`always` — modified key reporting |
| `extended-keys-format` | `csi-u` | `csi-u` or `xterm` — format for extended keys |
| `focus-events` | `off` | pass focus events through to applications |
| `history-file` | — | path to command history file |
| `input-buffer-size` | — | max bytes for escape/control sequences |
| `message-limit` | `1000` | number of messages to save per client |
| `prompt-history-limit` | `100` | number of prompt history items to save |
| `set-clipboard` | `external` | `on`/`external`/`off` — terminal clipboard |
| `terminal-features[]` | — | declare terminal features (see below) |
| `terminal-overrides[]` | — | override terminfo entries |
| `user-keys[]` | — | user-defined key escape sequences |
| `variation-selector-always-wide` | `off` | treat VS16 as wide character |

### `terminal-features[]`
Format: `"terminal-glob:feature1:feature2:..."`

Key features:
| Feature | Description |
|---------|-------------|
| `256` | 256-colour SGR support |
| `RGB` | true colour (24-bit) SGR support |
| `clipboard` | system clipboard via OSC 52 |
| `ccolour` | cursor colour setting |
| `cstyle` | cursor style setting |
| `extkeys` | extended key sequences |
| `focus` | focus reporting |
| `hyperlinks` | OSC 8 hyperlinks |
| `margins` | DECSLRM margins |
| `mouse` | xterm mouse sequences |
| `osc7` | OSC 7 working directory |
| `overline` | overline SGR attribute |
| `rectfill` | DECFRA rectangle fill |
| `sixel` | SIXEL graphics |
| `strikethrough` | strikethrough SGR |
| `sync` | synchronized updates |
| `title` | xterm title setting |
| `usstyle` | underscore style and colour |

```bash
# Enable true colour for all terminals:
set -ga terminal-features "*:RGB"
# Or use terminal-overrides:
set -ga terminal-overrides ",*:Tc"
```

---

## Session Options

Set with `set -g`. Display with `show -g`.

### Behaviour

| Option | Default | Description |
|--------|---------|-------------|
| `activity-action` | `other` | `any`/`none`/`current`/`other` — action on window activity |
| `assume-paste-time` | `1` | ms threshold for detecting paste vs. typing |
| `base-index` | `0` | starting window index |
| `bell-action` | `any` | `any`/`none`/`current`/`other` — action on bell |
| `default-command` | — | command for new windows (empty = login shell) |
| `default-shell` | `$SHELL` | shell binary path |
| `default-size` | `80x24` | size for detached sessions |
| `destroy-unattached` | `off` | `off`/`on`/`keep-last`/`keep-group` |
| `detach-on-destroy` | `on` | `off`/`on`/`no-detached`/`previous`/`next` |
| `display-panes-time` | `1000` | ms to show `display-panes` indicators |
| `display-time` | `750` | ms to show messages (0 = until key press) |
| `history-limit` | `2000` | lines of scrollback history per pane |
| `initial-repeat-time` | `0` | ms for initial key repeat (0 = use repeat-time) |
| `key-table` | `root` | default key table |
| `lock-after-time` | `0` | seconds of inactivity before locking (0 = off) |
| `lock-command` | `lock -np` | command to run when locking |
| `mouse` | `off` | enable mouse support |
| `prefix` | `C-b` | primary prefix key |
| `prefix2` | — | secondary prefix key |
| `prefix-timeout` | `0` | ms to wait after prefix (0 = no timeout) |
| `renumber-windows` | `off` | auto-renumber windows when one is closed |
| `repeat-time` | `500` | ms window for prefix-less key repeat |
| `set-titles` | `off` | set terminal window title |
| `set-titles-string` | `#T` | format for terminal title |
| `silence-action` | `other` | action on window silence |
| `status-keys` | `emacs` | `vi` or `emacs` — key bindings in command prompt |
| `update-environment[]` | — | env vars to copy when attaching |
| `visual-activity` | `off` | `on`/`off`/`both` — message on activity |
| `visual-bell` | `off` | `on`/`off`/`both` — message on bell |
| `visual-silence` | `off` | `on`/`off`/`both` — message on silence |
| `word-separators` | ` ` | characters considered word separators in copy mode |

### Cursor in Prompt

| Option | Default | Description |
|--------|---------|-------------|
| `prompt-cursor-colour` | `default` | colour of cursor in command prompt |
| `prompt-cursor-style` | `default` | style of cursor in command prompt |

### Status Line Content

See also: [theming.md](theming.md) for style options.

| Option | Default | Description |
|--------|---------|-------------|
| `status` | `on` | `off`/`on`/`2`/`3`/`4`/`5` |
| `status-format[]` | (built-in) | format for each status line row |
| `status-interval` | `15` | seconds between status refreshes |
| `status-justify` | `left` | `left`/`centre`/`right`/`absolute-centre` |
| `status-left` | `[#S] ` | left section content |
| `status-left-length` | `10` | max chars for left section |
| `status-right` | `"#T" %H:%M %d-%b-%y` | right section content |
| `status-right-length` | `40` | max chars for right section |
| `status-position` | `bottom` | `top` or `bottom` |

### Activity/Alert Options

| Option | Default | Description |
|--------|---------|-------------|
| `display-panes-active-colour` | `red` | active pane indicator colour |
| `display-panes-colour` | `blue` | inactive pane indicator colour |

---

## Window Options

Set with `set -wg` (global) or `set -w -t window`. Display with `show -wg`.

### Layout & Behaviour

| Option | Default | Description |
|--------|---------|-------------|
| `aggressive-resize` | `off` | resize to smallest/largest session |
| `automatic-rename` | `on` | auto-rename based on current command |
| `automatic-rename-format` | `#{?pane_in_mode,[tmux],#{pane_current_command}}#{?pane_dead,[dead],}` | format for auto-name |
| `fill-character` | ` ` | char for unused terminal space |
| `main-pane-height` | `24` | height of main pane in main-horizontal layout |
| `main-pane-width` | `80` | width of main pane in main-vertical layout |
| `mode-keys` | `emacs` | `vi` or `emacs` — copy mode key bindings |
| `monitor-activity` | `off` | highlight windows with activity |
| `monitor-bell` | `on` | highlight windows with bell |
| `monitor-silence` | `0` | seconds of silence before alert (0 = off) |
| `other-pane-height` | `0` | height of other panes in main-horizontal |
| `other-pane-width` | `0` | width of other panes in main-vertical |
| `pane-base-index` | `0` | starting index for pane numbers |
| `tiled-layout-max-columns` | `0` | max columns in tiled layout (0 = unlimited) |
| `window-size` | `latest` | `largest`/`smallest`/`manual`/`latest` |
| `wrap-search` | `on` | wrap search at end of pane content |

### Copy Mode Format

| Option | Default | Description |
|--------|---------|-------------|
| `copy-mode-position-format` | — | format for copy mode position indicator |

---

## Pane Options

Set with `set -p -t pane` or `set -wg` to apply to all panes in new windows.

| Option | Default | Description |
|--------|---------|-------------|
| `allow-passthrough` | `off` | `on`/`off`/`all` — allow applications to bypass tmux |
| `allow-rename` | `off` | allow `\ek...\e\\` escape to rename window |
| `allow-set-title` | `on` | allow `\e]2;...\e\\` escape to set pane title |
| `alternate-screen` | `on` | allow alternate screen (smcup/rmcup) |
| `cursor-colour` | `default` | pane cursor colour |
| `cursor-style` | `default` | `default`/`blinking-block`/`block`/`blinking-underline`/`underline`/`blinking-bar`/`bar` |
| `pane-colours[]` | — | palette colour overrides (index 0–255) |
| `remain-on-exit` | `off` | `on`/`off`/`failed` — keep pane after process exits |
| `remain-on-exit-format` | — | text shown at bottom of exited panes |
| `scroll-on-clear` | `on` | scroll content into history on clear |
| `synchronize-panes` | `off` | duplicate input to all panes in window |

---

## Hooks

Hooks run tmux commands when triggered. Stored as array options.

```bash
# Set a hook:
set-hook -g after-split-window "select-layout even-vertical"

# Array index for multiple hooks on same event:
set-hook -g pane-mode-changed[0] "..."
set-hook -g pane-mode-changed[1] "..."

# Unset:
set-hook -gu after-split-window

# Run immediately:
set-hook -gR session-created
```

### Available Hooks

| Hook | Trigger |
|------|---------|
| `alert-activity` | window has activity (monitor-activity on) |
| `alert-bell` | window received bell |
| `alert-silence` | window has been silent |
| `client-active` | client becomes latest active client |
| `client-attached` | client attaches |
| `client-detached` | client detaches |
| `client-focus-in` | focus enters client |
| `client-focus-out` | focus leaves client |
| `client-resized` | client resizes |
| `client-session-changed` | client switches session |
| `client-light-theme` | terminal switches to light theme |
| `client-dark-theme` | terminal switches to dark theme |
| `command-error` | a tmux command fails |
| `pane-died` | pane process exits with remain-on-exit |
| `pane-exited` | pane process exits |
| `pane-focus-in` | focus enters pane (focus-events on) |
| `pane-focus-out` | focus leaves pane |
| `pane-mode-changed` | pane enters/exits a mode |
| `pane-set-clipboard` | terminal clipboard set via OSC 52 |
| `session-created` | new session created |
| `session-closed` | session closed |
| `session-renamed` | session renamed |
| `window-layout-changed` | window layout changes |
| `window-linked` | window linked to session |
| `window-renamed` | window renamed |
| `window-resized` | window resizes |
| `window-unlinked` | window unlinked from session |
| `after-<command>` | after any command completes (e.g., `after-new-window`) |

---

## Key Bindings

```bash
# Bind: prefix + key
bind-key r source-file ~/.tmux.conf \; display "Reloaded!"

# Bind without prefix:
bind-key -n C-S-Left swap-window -t -1

# Bind in specific table:
bind-key -T copy-mode-vi v send-keys -X begin-selection

# Unbind:
unbind-key C-b

# List all bindings:
tmux list-keys
```

### Key Binding Flags

| Flag | Description |
|------|-------------|
| `-n` | no prefix required (root table) |
| `-r` | key may repeat (within `repeat-time` ms) |
| `-T table` | bind in key table (default: prefix) |

### Default Key Tables

- `root` — keys pressed without prefix
- `prefix` — keys pressed after prefix
- `copy-mode` — emacs copy mode
- `copy-mode-vi` — vi copy mode

### Multiple Prefix Keys (Chord Sequences)

```bash
# Make C-a an additional prefix:
set -g prefix2 C-a
bind-key C-a send-prefix -2

# Or create chord sequences:
bind-key -Ttable2 c list-keys
bind-key -Ttable1 b switch-client -Ttable2
bind-key -Troot   a switch-client -Ttable1
# Now a→b→c runs list-keys
```

---

## Mouse Support

```bash
set -g mouse on
```

### Mouse Key Binding Format

```
MouseDown1Pane    MouseUp1Status    WheelUpPane
MouseDown1Border  MouseUp1StatusLeft
MouseDown2Pane    DoubleClick1Pane
```

Events: `WheelUp`, `WheelDown`, `MouseDown1-3`, `MouseUp1-3`,
`MouseDrag1-3`, `MouseDragEnd1-3`, `SecondClick1-3`, `DoubleClick1-3`, `TripleClick1-3`

Locations: `Pane`, `Border`, `Status`, `StatusLeft`, `StatusRight`, `StatusDefault`,
`ScrollbarSlider`, `ScrollbarUp`, `ScrollbarDown`

### Mouse Binding Examples

```bash
# Drag to resize panes, click to select:
bind-key -n MouseDown1Pane select-pane -t = \; send-keys -M
bind-key -n WheelUpPane if-shell -F -t = "#{pane_in_mode}" \
    "send-keys -M" "copy-mode -e"

# Right-click for a menu:
bind-key -n MouseDown3Pane display-menu -T "Pane" \
    "Split Horizontal" h "split-window -h" \
    "Split Vertical"   v "split-window -v" \
    "Kill Pane"        x kill-pane
```

### `{mouse}` Target

Use `{mouse}` (or `=`) to target the pane/window where mouse event occurred:
```bash
bind-key -n MouseDown1Status select-window -t=
bind-key -n MouseDown3Status display-menu -T "#{window_name}" -t= -x M -y S \
    "Rename" r "command-prompt -I '#W' { rename-window '%%' }"
```
