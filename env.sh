#!/bin/sh

[ -n "$ODSOD_MACHINE" ] && return || export ODSOD_MACHINE=1

# machine
export PATH="$HOME/.local/bin:$PATH"

# encore
export ENCORE_INSTALL="$HOME/.local/share/odsod/machine/encore"
export PATH="$ENCORE_INSTALL/bin:$PATH"

# gemini-cli
export GOOGLE_CLOUD_PROJECT="way-local-dev"
export GOOGLE_CLOUD_LOCATION="global"
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

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
export EDITOR="vim"

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
