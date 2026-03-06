# XDG Base Directory Compliance
# Source this file from your .zshrc or .profile:
#   source "$XDG_CONFIG_HOME/shell/xdg-env.sh"

# --- Rust ---
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup

# --- CUDA ---
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv

# --- .NET ---
export DOTNET_CLI_HOME="$XDG_DATA_HOME"/dotnet

# --- Docker ---
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# --- GnuPG ---
export GNUPGHOME="$XDG_DATA_HOME"/gnupg

# --- Java ---
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

# --- Julia ---
export JULIA_DEPOT_PATH="$XDG_DATA_HOME/julia:$JULIA_DEPOT_PATH"
export JULIAUP_DEPOT_PATH="$XDG_DATA_HOME"/julia

# --- npm ---
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME"/npm/config/npm-init.js
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME"/npm
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR"/npm

# --- NVM ---
export NVM_DIR="$XDG_CONFIG_HOME"/nvm

# --- Bun ---
export BUN_INSTALL="$HOME"/.bun

# --- SDKMAN ---
export SDKMAN_DIR="$XDG_DATA_HOME"/sdkman

# --- Visual Studio Code ---
export VSCODE_CONFIG="$XDG_CONFIG_HOME"/vscode