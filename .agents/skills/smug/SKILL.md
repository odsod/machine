---
name: smug
description: Manage tmux sessions with YAML configurations. Use when the user wants to automate their tmux workflow, including creating sessions, windows, and panes with specific layouts, hooks, and commands.
---

# Smug - tmux session manager

Smug automates your tmux workflow by using a single YAML configuration file to define sessions, windows, panes, and automated hooks.

## Quick Start

### Core Commands

- `smug start <project>`: Start a project session. (Alias: `smug <project>`, `smug switch <project>`)
- `smug stop <project>`: Stop a project session.
- `smug list`: List available project configurations.
- `smug new <project>`: Create a new project configuration.
- `smug edit <project>`: Edit an existing project configuration in `$EDITOR`.
- `smug print`: Output current session configuration to stdout.
- `smug rm <project>`: Remove a project configuration.

### Common Options

- `-f, --file <file>`: Use a custom path to a configuration file. By default looks for `.smug.yml` in CWD or `~/.config/smug/<project>.yml`.
- `-w, --windows <window>`: List of windows to start or stop.
- `-a, --attach`: Force switch client for a session (overriding config defaults).
- `-i, --inside-current-session`: Create all windows inside the current tmux session instead of a new one.
- `-d, --debug`: Print all executed commands to `~/.config/smug/smug.log`.
- `--detach`: Detach session (equivalent to `tmux -d`).

---

## Configuration Workflows

### 1. Variables & Environment Interpolation

Smug expands `${VARIABLE}` syntax in your YAML config. It checks variables passed via CLI first, then falls back to your OS environment variables.

**Config:**
```yaml
session: my-project
root: ~/Projects/${PROJECT_NAME}
env:
  NODE_ENV: ${ENV:-development}
```

**Execution:**
```console
$ smug start my-project PROJECT_NAME=frontend ENV=production
```
*Note: `SMUG_SESSION` and `SMUG_SESSION_CONFIG_PATH` are automatically injected into the session's environment.*

### 2. Grouping Projects in Directories

You can organize your configs into subdirectories inside `~/.config/smug/`. If you run `smug start <dirname>`, Smug will sequentially start **all** configs found in that directory.

**Important**: `smug start <dirname>/<name>` does **not** work — smug cannot start individual configs inside subdirectories by project name. To start a specific config in a subdirectory, use `-f`:

```console
$ smug start -f ~/.config/smug/<dirname>/<name>.yml
```

To avoid this limitation, keep configs as **flat files** directly in `~/.config/smug/` so `smug start <name>` works as expected.

### 3. Optional "Manual" Windows

You can define background services or secondary windows in your config but prevent them from starting automatically by using `manual: true`.

```yaml
windows:
  - name: server
    commands: ["npm start"]
  - name: heavy-worker
    manual: true
    commands: ["npm run process-queue"]
```
To start the manual window later:
- `smug start project:heavy-worker` 
- `smug start project -w heavy-worker`

### 4. Setup Hooks & Teardown

Smug allows precise control over commands that run outside of tmux panes during the session lifecycle.

- **Session Hooks**:
  - `before_start`: Commands executed (via standard shell) *before* tmux session creation.
  - `stop`: Commands executed *before* the tmux session is killed.
  - `attach_hook`: Command executed every time the *first* client attaches.
  - `detach_hook`: Command executed every time the *last* client detaches.
- **Window Hooks**:
  - `before_start`: Commands executed before the specific window is created.

### 5. Advanced Tmux Integration

You can override tmux's core options at the root of your Smug config to run isolated tmux servers or custom configurations:

```yaml
session: isolated-env
socket_name: custom_socket   # Translates to tmux -L custom_socket
# socket_path: /tmp/tmux.sock # Translates to tmux -S /tmp/tmux.sock (overrides socket_name)
# config_file: ~/.tmux.custom.conf # Translates to tmux -f
```

---

## Example Complex Configuration

```yaml
session: full-stack
root: ~/Developer/webapp
attach: true
socket_name: webapp_tmux

env:
  API_KEY: ${SECRET_KEY}

before_start:
  - docker-compose up -d db redis

stop:
  - docker-compose stop

windows:
  - name: editor
    selected: true # This window will be focused when attaching
    layout: main-vertical
    before_start:
      - npm install # Ensure deps are ready before opening editor
    commands:
      - nvim .
    panes:
      - type: horizontal
        commands:
          - tail -f logs/dev.log
          
  - name: services
    layout: tiled
    panes:
      - commands: ["npm run start:api"]
      - commands: ["npm run start:web"]

  - name: ssh-prod
    manual: true
    commands:
      - ssh prod.example.com
```

## References
- **[api_reference.md](references/api_reference.md)**: Full schema definition for all YAML fields.
- **[README.md](references/smug/README.md)**: Original project README.
