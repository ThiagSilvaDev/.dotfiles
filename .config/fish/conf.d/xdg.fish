# =============================================================================
# 2. CONFIGURATION (XDG_CONFIG_HOME -> ~/.config)
# Settings, preferences, and initialization scripts
# =============================================================================
set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"
set -gx VSCODE_CONFIG "$XDG_CONFIG_HOME/vscode"
set -gx WGETRC "$XDG_CONFIG_HOME/wgetrc"

# Node / JS
set -gx NVM_DIR "$XDG_CONFIG_HOME/nvm"
set -gx nvm_data "$NVM_DIR"
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
set -gx NPM_CONFIG_INIT_MODULE "$XDG_CONFIG_HOME/npm/config/npm-init.js"

# =============================================================================
# 3. DATA & SDKS (XDG_DATA_HOME -> ~/.local/share)
# Downloaded packages, binaries, and language environments
# =============================================================================
set -gx GNUPGHOME "$XDG_DATA_HOME/gnupg"

# Languages & Package Managers
set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
set -gx DOTNET_CLI_HOME "$XDG_DATA_HOME/dotnet"
set -gx GOPATH "$XDG_DATA_HOME/go"
set -gx PYENV_ROOT "$XDG_DATA_HOME/pyenv"
set -gx JULIA_DEPOT_PATH "$XDG_DATA_HOME/julia:$JULIA_DEPOT_PATH"
set -gx JULIAUP_DEPOT_PATH "$XDG_DATA_HOME/julia"
set -gx PNPM_HOME "$XDG_DATA_HOME/pnpm"

# Java Ecosystem
set -gx SDKMAN_DIR "$XDG_DATA_HOME/sdkman"
set -gx GRADLE_USER_HOME "$XDG_DATA_HOME/gradle"

# =============================================================================
# 4. STATE & HISTORY (XDG_STATE_HOME -> ~/.local/state)
# Log files, shell histories, and command records
# =============================================================================
set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"
set -gx PSQL_HISTORY "$XDG_STATE_HOME/psql_history"
set -gx MYSQL_HISTFILE "$XDG_STATE_HOME/mysql_history"

# =============================================================================
# 5. CACHE & RUNTIME (XDG_CACHE_HOME / XDG_RUNTIME_DIR)
# Throwaway data that can be safely deleted
# =============================================================================
set -gx CUDA_CACHE_PATH "$XDG_CACHE_HOME/nv"
set -gx NPM_CONFIG_CACHE "$XDG_CACHE_HOME/npm"
set -gx NPM_CONFIG_TMP (set -q XDG_RUNTIME_DIR; and echo "$XDG_RUNTIME_DIR/npm"; or echo "$XDG_CACHE_HOME/npm")

# =============================================================================
# 6. EXCEPTIONS (Hardcoded or Homebound)
# =============================================================================
# Bun aggressively defaults to ~/.bun and ignores XDG natively without strict
# path hacking, so it's often best left here.
set -gx BUN_INSTALL "$HOME/.bun"
