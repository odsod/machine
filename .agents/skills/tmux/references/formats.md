# tmux Formats Reference

## Table of Contents
1. [Basic Syntax](#basic-syntax)
2. [Short Aliases](#short-aliases)
3. [All Format Variables](#all-format-variables)
4. [Modifiers & Operators](#modifiers--operators)
5. [Shell Commands](#shell-commands)
6. [strftime Integration](#strftime-integration)
7. [Examples](#examples)

---

## Basic Syntax

Format variables are enclosed in `#{` and `}`:
```
#{session_name}    → current session name
#{window_index}    → current window index
#{pane_title}      → pane title
```

Special escapes:
- `##` → literal `#`
- `#,` → literal `,` (inside conditionals only)
- `#}` → literal `}` (inside conditionals only)

---

## Short Aliases

| Alias | Equivalent |
|-------|-----------|
| `#S` | `#{session_name}` |
| `#W` | `#{window_name}` |
| `#I` | `#{window_index}` |
| `#F` | `#{window_flags}` |
| `#P` | `#{pane_index}` |
| `#T` | `#{pane_title}` |
| `#H` | `#{host}` |
| `#h` | `#{host_short}` |
| `#D` | `#{pane_id}` |
| `#(cmd)` | shell command output |
| `#[style]` | inline style |

---

## All Format Variables

### Session Variables

| Variable | Description |
|----------|-------------|
| `session_name` | Name of session |
| `session_id` | Unique session ID (prefixed `$`) |
| `session_index` | Index of session |
| `session_path` | Working directory of session |
| `session_windows` | Number of windows in session |
| `session_attached` | Number of clients attached |
| `session_attached_list` | List of attached clients |
| `session_created` | Time session was created |
| `session_activity` | Time of last session activity |
| `session_last_attached` | Time session last attached |
| `session_active` | 1 if session is active |
| `session_alerts` | List of window indexes with alerts |
| `session_activity_flag` | 1 if any window has activity |
| `session_bell_flag` | 1 if any window has bell |
| `session_silence_flag` | 1 if any window has silence alert |
| `session_stack` | Window indexes in most recent order |
| `session_format` | 1 if format is for a session |
| `session_grouped` | 1 if session is in a group |
| `session_group` | Name of session group |
| `session_group_size` | Number of sessions in group |
| `session_group_list` | List of sessions in group |
| `session_group_attached` | Clients attached to group sessions |
| `session_group_attached_list` | List of clients in group |
| `session_group_many_attached` | 1 if multiple clients in group |
| `session_many_attached` | 1 if multiple clients attached |
| `session_marked` | 1 if session contains marked pane |
| `last_session_index` | Index of last session |
| `server_sessions` | Total number of sessions |
| `next_session_id` | Unique ID for next new session |

### Window Variables

| Variable | Description |
|----------|-------------|
| `window_name` | Name of window |
| `window_id` | Unique window ID (prefixed `@`) |
| `window_index` | Index of window |
| `window_flags` | Window flags (with `#` escaped as `##`) |
| `window_raw_flags` | Window flags (unescaped) |
| `window_width` | Width of window |
| `window_height` | Height of window |
| `window_active` | 1 if window is active |
| `window_activity` | Time of last window activity |
| `window_activity_flag` | 1 if window has activity |
| `window_bell_flag` | 1 if window has bell |
| `window_silence_flag` | 1 if window has silence alert |
| `window_last_flag` | 1 if window is last used |
| `window_start_flag` | 1 if window has lowest index |
| `window_end_flag` | 1 if window has highest index |
| `window_bigger` | 1 if window is larger than client |
| `window_zoomed_flag` | 1 if window is zoomed |
| `window_marked_flag` | 1 if window contains marked pane |
| `window_linked` | 1 if window is linked across sessions |
| `window_linked_sessions` | Number of sessions this window is linked to |
| `window_linked_sessions_list` | List of sessions |
| `window_format` | 1 if format is for a window |
| `window_layout` | Layout description (ignoring zoom) |
| `window_visible_layout` | Layout description (respecting zoom) |
| `window_panes` | Number of panes in window |
| `window_stack_index` | Index in session most-recent stack |
| `window_offset_x` | X offset when window larger than client |
| `window_offset_y` | Y offset when window larger than client |
| `window_active_clients` | Number of clients viewing this window |
| `window_active_clients_list` | List of clients viewing this window |
| `window_active_sessions` | Number of sessions on which window is active |
| `window_active_sessions_list` | List of sessions on which window is active |
| `window_cell_height` | Height of each cell in pixels |
| `window_cell_width` | Width of each cell in pixels |
| `active_window_index` | Index of active window in session |
| `last_window_index` | Index of last window in session |

### Pane Variables

| Variable | Description |
|----------|-------------|
| `pane_id` | Unique pane ID (prefixed `%`) |
| `pane_index` | Index of pane |
| `pane_pid` | PID of first process in pane |
| `pane_tty` | Pseudo terminal of pane |
| `pane_title` | Title of pane (set by application) |
| `pane_path` | Path of pane (can be set by application) |
| `pane_current_command` | Current command running in pane |
| `pane_current_path` | Current directory of pane |
| `pane_start_command` | Command pane started with |
| `pane_start_path` | Path pane started with |
| `pane_width` | Width of pane |
| `pane_height` | Height of pane |
| `pane_left` | Left edge position of pane |
| `pane_right` | Right edge position of pane |
| `pane_top` | Top edge position of pane |
| `pane_bottom` | Bottom edge position of pane |
| `pane_active` | 1 if pane is active |
| `pane_last` | 1 if pane was last active |
| `pane_at_left` | 1 if pane is at left edge of window |
| `pane_at_right` | 1 if pane is at right edge |
| `pane_at_top` | 1 if pane is at top of window |
| `pane_at_bottom` | 1 if pane is at bottom |
| `pane_dead` | 1 if pane process has exited |
| `pane_dead_signal` | Exit signal of dead pane process |
| `pane_dead_status` | Exit status of dead pane process |
| `pane_dead_time` | Exit time of dead pane process |
| `pane_format` | 1 if format is for a pane |
| `pane_in_mode` | Number of modes pane is in |
| `pane_mode` | Name of current mode |
| `pane_marked` | 1 if this is the marked pane |
| `pane_marked_set` | 1 if a marked pane exists |
| `pane_synchronized` | 1 if pane is synchronized |
| `pane_input_off` | 1 if input to pane is disabled |
| `pane_pipe` | 1 if pane is being piped |
| `pane_bg` | Pane background colour |
| `pane_fg` | Pane foreground colour |
| `pane_tabs` | Pane tab positions |
| `pane_unseen_changes` | 1 if changes occurred while in mode |
| `pane_key_mode` | Extended key reporting mode |
| `pane_search_string` | Last search string in copy mode |

### Cursor Variables

| Variable | Description |
|----------|-------------|
| `cursor_x` | Cursor X position |
| `cursor_y` | Cursor Y position |
| `cursor_character` | Character at cursor |
| `cursor_colour` | Cursor colour |
| `cursor_shape` | Cursor shape |
| `cursor_blinking` | 1 if cursor is blinking |
| `cursor_very_visible` | 1 if cursor is in very visible mode |
| `cursor_flag` | Pane cursor flag |
| `insert_flag` | Pane insert flag |
| `keypad_cursor_flag` | Pane keypad cursor flag |
| `keypad_flag` | Pane keypad flag |
| `origin_flag` | Pane origin flag |
| `wrap_flag` | Pane wrap flag |
| `alternate_on` | 1 if pane is in alternate screen |
| `alternate_saved_x` | Saved cursor X in alternate screen |
| `alternate_saved_y` | Saved cursor Y in alternate screen |
| `scroll_position` | Scroll position in copy mode |
| `scroll_region_lower` | Bottom of scroll region |
| `scroll_region_upper` | Top of scroll region |

### Copy Mode Variables

| Variable | Description |
|----------|-------------|
| `copy_cursor_line` | Line cursor is on in copy mode |
| `copy_cursor_word` | Word under cursor in copy mode |
| `copy_cursor_x` | Cursor X in copy mode |
| `copy_cursor_y` | Cursor Y in copy mode |
| `copy_cursor_hyperlink` | Hyperlink under cursor in copy mode |
| `search_present` | 1 if search started in copy mode |
| `search_count` | Count of search results |
| `search_count_partial` | 1 if search count is partial |
| `search_match` | Current search match |
| `selection_active` | 1 if selection changes with cursor |
| `selection_present` | 1 if selection exists |
| `selection_start_x` | X position of selection start |
| `selection_start_y` | Y position of selection start |
| `selection_end_x` | X position of selection end |
| `selection_end_y` | Y position of selection end |
| `rectangle_toggle` | 1 if rectangle selection is on |

### Client Variables

| Variable | Description |
|----------|-------------|
| `client_name` | Name of client |
| `client_pid` | PID of client process |
| `client_uid` | UID of client process |
| `client_user` | User of client process |
| `client_tty` | Pseudo terminal of client |
| `client_termname` | Terminal name |
| `client_termtype` | Terminal type |
| `client_termfeatures` | Terminal features |
| `client_width` | Width of client |
| `client_height` | Height of client |
| `client_cell_width` | Width of each client cell in pixels |
| `client_cell_height` | Height of each client cell in pixels |
| `client_created` | Time client was created |
| `client_activity` | Time client last had activity |
| `client_session` | Name of client's current session |
| `client_last_session` | Name of client's last session |
| `client_key_table` | Current key table |
| `client_prefix` | 1 if prefix key has been pressed |
| `client_readonly` | 1 if client is read-only |
| `client_control_mode` | 1 if client is in control mode |
| `client_utf8` | 1 if client supports UTF-8 |
| `client_flags` | List of client flags |
| `client_discarded` | Bytes discarded when client is behind |
| `client_written` | Bytes written to client |

### Host & Server Variables

| Variable | Description |
|----------|-------------|
| `host` | Hostname (full) |
| `host_short` | Hostname (no domain) |
| `pid` | Server PID |
| `uid` | Server UID |
| `user` | Server user |
| `version` | Server version |
| `socket_path` | Server socket path |
| `start_time` | Server start time |
| `sixel_support` | 1 if server supports SIXEL |
| `config_files` | List of configuration files loaded |
| `current_file` | Current configuration file |
| `line` | Line number in list |
| `loop_last_flag` | 1 if last item in W:/P:/S:/L: loop |

### Mouse Variables

| Variable | Description |
|----------|-------------|
| `mouse_x` | Mouse X position |
| `mouse_y` | Mouse Y position |
| `mouse_line` | Line under mouse |
| `mouse_word` | Word under mouse |
| `mouse_hyperlink` | Hyperlink under mouse |
| `mouse_status_line` | Status line on which mouse event occurred |
| `mouse_status_range` | Range type or argument of mouse event |
| `mouse_all_flag` | Pane mouse all flag |
| `mouse_any_flag` | Pane mouse any flag |
| `mouse_button_flag` | Pane mouse button flag |
| `mouse_sgr_flag` | Pane mouse SGR flag |
| `mouse_standard_flag` | Pane mouse standard flag |
| `mouse_utf8_flag` | Pane mouse UTF-8 flag |

### Hook Variables (Available Inside Hooks)

| Variable | Description |
|----------|-------------|
| `hook` | Name of running hook |
| `hook_client` | Name of client where hook ran |
| `hook_pane` | ID of pane where hook ran |
| `hook_session` | ID of session where hook ran |
| `hook_session_name` | Name of session where hook ran |
| `hook_window` | ID of window where hook ran |
| `hook_window_name` | Name of window where hook ran |

### Buffer Variables (Available in Buffer Mode)

| Variable | Description |
|----------|-------------|
| `buffer_name` | Name of buffer |
| `buffer_created` | Time buffer was created |
| `buffer_size` | Size of buffer in bytes |
| `buffer_sample` | Sample of buffer start |
| `buffer_full` | Full buffer content |

### Command Variables (Available in Command Mode)

| Variable | Description |
|----------|-------------|
| `command` | Name of current command |
| `command_list_alias` | Command alias if listing commands |
| `command_list_name` | Command name if listing commands |
| `command_list_usage` | Command usage if listing commands |

---

## Modifiers & Operators

### Conditionals `#{?...}`

```
#{?condition,if_true,if_false}
```

Multiple conditions (like if/elif/else):
```
#{?cond1,val1,cond2,val2,default}
```

Inside conditionals, escape `,` as `#,` and `}` as `#}` when not in `#{...}`:
```
#{?pane_in_mode,#[fg=white#,bg=red],#[fg=red#,bg=white]}
```

### Comparisons

| Syntax | Description |
|--------|-------------|
| `#{==:a,b}` | 1 if a equals b |
| `#{!=:a,b}` | 1 if a not equals b |
| `#{<:a,b}` | 1 if a less than b |
| `#{>:a,b}` | 1 if a greater than b |
| `#{<=:a,b}` | 1 if a less than or equal |
| `#{>=:a,b}` | 1 if a greater than or equal |
| `#{||:a,b}` | 1 if a OR b is true |
| `#{&&:a,b}` | 1 if a AND b is true |
| `#{!:a}` | 1 if a is false |
| `#{!!:a}` | canonical boolean (1 or 0) |

### Pattern Matching `#{m:...}`

```
#{m:*foo*,#{host}}        # glob match (case sensitive)
#{m/i:*foo*,#{host}}      # glob match (case insensitive)
#{m/r:^start,#{host}}     # regex match
#{m/ri:^start,#{host}}    # regex match (case insensitive)
```

### Pane Content Search `#{C:...}`

```
#{C:pattern}        # search pane content, 0 if not found, line number if found
#{C/r:^regex}       # regex search in pane content
#{C/ri:^regex}      # case-insensitive regex search
```

### Numeric Operations `#{e|op|...}`

| Syntax | Operation |
|--------|-----------|
| `#{e|+|:a,b}` | a + b |
| `#{e|-|:a,b}` | a - b |
| `#{e|*|:a,b}` | a × b |
| `#{e|/|:a,b}` | a ÷ b |
| `#{e|m|:a,b}` | a mod b |
| `#{e|%%|:a,b}` | a mod b (for strftime contexts) |
| `#{e|==|:a,b}` | 1 if a == b |
| `#{e|!=|:a,b}` | 1 if a != b |
| `#{e|<|:a,b}` | 1 if a < b |
| `#{e|>|:a,b}` | 1 if a > b |

Add `f` for floating point: `#{e|*|f|4:5.5,3}` (4 decimal places).

### String Length & Width

| Syntax | Description |
|--------|-------------|
| `#{n:var}` | number of characters in value |
| `#{w:var}` | display width of value |

### Truncation `#{=...}`

```
#{=5:pane_title}         # first 5 chars
#{=-5:pane_title}        # last 5 chars
#{=/5/...:pane_title}    # first 5 chars, append "..." if truncated
#{=/-5/...:pane_title}   # last 5 chars with prefix if truncated
```

### Padding `#{p...}`

```
#{p10:window_name}    # pad to 10 chars (left-aligned, space on right)
#{p-10:window_name}   # pad to 10 chars, right-aligned (space on left)
```

### Repetition `#{R:...}`

```
#{R:─,40}    # repeat ─ character 40 times
```

### Substitution `#{s/...}`

```
#{s/foo/bar/:window_name}           # replace "foo" with "bar"
#{s/foo/bar/i:window_name}          # case insensitive
#{s/a(.)/\1x/i:window_name}         # regex with capture group
#{s|foo/|bar/|:window_name}         # different delimiter (| instead of /)
```

### Path Operations

```
#{b:pane_current_path}    # basename
#{d:pane_current_path}    # dirname
```

### Escaping

```
#{q:value}     # escape sh(1) special characters
#{q/h:value}   # escape hash characters (# → ##)
```

### Expansion

```
#{E:status-left}    # expand the value of an option as a format
#{T:status-left}    # expand option value AND strftime specifiers
```

### Loops (Iterate Over Sessions/Windows/Panes/Clients)

```
#{S:format}              # loop over sessions
#{W:format}              # loop over windows
#{P:format}              # loop over panes
#{L:format}              # loop over clients
```

With current-item highlighting (second format used for current):
```
#{W:#{E:window-status-format} ,#{E:window-status-current-format} }
```

Sort modifiers: `/i` (index), `/n` (name), `/t` (activity time), `/r` (reverse):
```
#{S/nr:#{session_name} }    # sessions sorted by name, reversed
```

### Name Existence Check

```
#{N/w:mywindow}    # 1 if a window named "mywindow" exists
#{N/s:mysession}   # 1 if a session named "mysession" exists
#{N:mywindow}      # same as N/w
```

### ASCII / Colour Conversion

```
#{a:65}         # ASCII char for code 65 → "A"
#{c:colour166}  # colour to 6-digit hex RGB → "d75f00"
```

### Literal (No Expansion)

```
#{l:#{?pane_in_mode,yes,no}}    # output literally: #{?pane_in_mode,yes,no}
```

### Chaining Modifiers

Multiple modifiers separated by `;`:
```
#{T;=10:status-left}    # expand status-left as format+strftime, limit to 10 chars
#{E;p20:window-name}    # expand option then pad to 20 chars
```

---

## Shell Commands

```
#(command)         # insert last line of command output
#(uptime)          # example: system uptime
#(date +%H:%M)     # current time via shell
```

**Important**: tmux does NOT wait for commands to finish. It uses the previous result.
Commands run at most once per second. For the first run, output is empty.

Commands run via `/bin/sh -c` with the tmux global environment.

---

## strftime Integration

Format variables with `t:` prefix convert timestamps to strings:
```
#{t:session_created}              # "Mon Jan  1 12:00:00 2024"
#{t/p:session_created}            # shorter human format for past times
#{t/f/%%Y-%%m-%%d:session_created}  # custom format (escape % as %%)
```

In `status-left`/`status-right`, strftime is applied directly:
```
set -g status-right "%H:%M %d-%b-%y"    # time and date via strftime
set -g status-right "%a %d %b %H:%M"   # Mon 01 Jan 12:00
```

---

## Examples

### Conditional style in window status
```bash
# Show lock icon if zoomed, flag otherwise
set -g window-status-format \
    "#{?window_zoomed_flag,#[fg=red]🔒,#[fg=default]}#I #W"
```

### Path truncation in status
```bash
# Show last 30 chars of current path in status-left
set -g status-left " #S │ #{=-30:pane_current_path} "
```

### Show git branch in status
```bash
set -g status-right "#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | head -c 20)"
```

### Loop to build custom window list
```bash
set -g status-format[0] \
    "#{W:#{?window_active,#[bold],#[nobold]}#{window_index}:#{window_name} ,}"
```

### Conditional colours based on prefix state
```bash
# Change status-left colour when prefix is active
set -g status-left "#{?client_prefix,#[bg=red],#[bg=blue]} #S "
```

### Pane path with basename only when deep
```bash
# Show dirname + "/" + basename
"#{d:#{d:pane_current_path}}/#{b:#{d:pane_current_path}}/#{b:pane_current_path}"
# Or simply:
"#{b:pane_current_path}"
```
