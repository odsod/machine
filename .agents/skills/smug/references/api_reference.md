# Smug Configuration Schema

The Smug configuration uses YAML to define tmux sessions, windows, and panes.

## Session Configuration

| Key             | Type                | Description                                                                 |
|-----------------|---------------------|-----------------------------------------------------------------------------|
| `session`       | `string`            | The name of the tmux session.                                              |
| `root`          | `string`            | The root directory for the session. Can be absolute or relative.            |
| `attach`        | `boolean`           | Automatically attach to the session after creation (defaults to `false`).  |
| `env`           | `map[string]string` | Environment variables to set for the session. `SMUG_SESSION` and `SMUG_SESSION_CONFIG_PATH` are implicitly added. |
| `before_start`  | `[]string`          | Shell commands to run **before** the tmux session is created.              |
| `stop`          | `[]string`          | Shell commands to run **before** the tmux session is killed.               |
| `attach_hook`   | `string`            | Shell command to run every time the **first** client attaches.             |
| `detach_hook`   | `string`            | Shell command to run every time the **last** client detaches.              |
| `sendkeys_timeout`| `int`             | Timeout for tmux send-keys commands.                                       |
| `windows`       | `[]Window`          | List of windows to create in the session.                                   |

### Tmux Core Overrides (Optional)

| Key           | Type     | Description                                                                     |
|---------------|----------|---------------------------------------------------------------------------------|
| `socket_name` | `string` | The tmux socket name to use (`-L` flag).                                        |
| `socket_path` | `string` | The tmux socket path to use (`-S` flag). Overrides `socket_name` if both exist. |
| `config_file` | `string` | Custom tmux configuration file path (`-f` flag). Expands `~` to home directory. |

---

## Window Configuration

| Key            | Type      | Description                                                                 |
|----------------|-----------|-----------------------------------------------------------------------------|
| `name`         | `string`  | The name of the window.                                                     |
| `root`         | `string`  | The root directory for the window (relative to the session's `root`).        |
| `manual`       | `boolean` | If `true`, the window is only started if specified manually (using `-w`).    |
| `selected`     | `boolean` | If `true`, this window will be selected/focused at the start of the session. |
| `layout`       | `string`  | The tmux layout to use (e.g., `main-vertical`, `main-horizontal`, `tiled`). |
| `before_start` | `[]string`| Shell commands to run **before** this specific window is created.            |
| `commands`     | `[]string`| Commands to run inside the **first** pane of the window.                     |
| `panes`        | `[]Pane`  | List of additional panes to create in the window.                           |

---

## Pane Configuration

| Key        | Type      | Description                                                                 |
|------------|-----------|-----------------------------------------------------------------------------|
| `type`     | `string`  | The type of split (`horizontal` or `vertical`).                            |
| `root`     | `string`  | The root directory for the pane.                                            |
| `commands` | `[]string`| Commands to run in the pane.                                                |

---

## Variable Interpolation

Smug automatically interpolates environment variables and explicitly passed settings in your configuration file using the `${VARIABLE}` syntax.

**Evaluation Order:**
1. Explicitly passed settings (e.g., `smug start project VAR=value`)
2. OS Environment variables
3. Unmodified string if the variable is not found.

Example:
```yaml
env:
  NODE_ENV: ${APP_ENV}
```