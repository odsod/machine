#!/bin/sh

[ -n "$ODSOD_MACHINE" ] && return || export ODSOD_MACHINE=1

# bat
export BAT_THEME="Nord"

# difftastic
export DFT_BACKGROUND="dark"
export DFT_DISPLAY="side-by-side"

# encore
export ENCORE_INSTALL="$HOME/.local/share/odsod/machine/encore"
export PATH="$ENCORE_INSTALL/bin:$PATH"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind 'ctrl-/:toggle-preview'"
export FZF_ALT_C_COMMAND="fd --type d --strip-cwd-prefix --hidden --follow --exclude .git"

# gum input
export GUM_INPUT_PROMPT="$ "
export GUM_INPUT_SHOW_HELP="false"
export GUM_INPUT_PROMPT_FOREGROUND="7"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="8"
export GUM_INPUT_CURSOR_FOREGROUND="7"
export GUM_INPUT_HEADER_FOREGROUND="3"
export GUM_INPUT_PADDING="1 2"

# gum choose
export GUM_CHOOSE_SHOW_HELP="false"
export GUM_CHOOSE_CURSOR_FOREGROUND="7"
export GUM_CHOOSE_HEADER_FOREGROUND="3"
export GUM_CHOOSE_ITEM_FOREGROUND="8"
export GUM_CHOOSE_SELECTED_FOREGROUND="7"
export GUM_CHOOSE_PADDING="1 2"

# gemini-cli
export GOOGLE_CLOUD_PROJECT="way-local-dev"
export GOOGLE_CLOUD_LOCATION="global"

# go
export GOROOT="$HOME/.local/share/odsod/machine/go"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# java
export JAVA_HOME="/usr/lib/jvm/java-25-openjdk"
export MAVEN_HOME="/usr/share/maven"
export PATH="$MAVEN_HOME/bin:$PATH"
export PATH="$JAVA_HOME/bin:$PATH"

# jetbrains-toolbox
export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"

# neovim
export EDITOR="nvim"

# npm
export PATH="$HOME/.local/share/npm/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# rust
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"
[ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"

# machine
export PATH="$HOME/.local/bin:$PATH"
