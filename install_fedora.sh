#!/usr/bin/env bash
#
# Config script for Fedora (XDG-compatible).
#

set -euo pipefail

# --- XDG Constants and Configurations ---
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

readonly FONT_DIR="${XDG_DATA_HOME}/fonts"
readonly FONT_NAME="JetBrainsMono"
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip"

readonly ANTIDOTE_URL="https://github.com/mattmc3/antidote.git"
readonly DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
readonly FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish"
readonly FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
readonly TPM_URL="https://github.com/tmux-plugins/tpm.git"
readonly NVIDIA_CUDA_REPO_BASE_URL="https://developer.download.nvidia.com/compute/cuda/repos"
readonly NVIDIA_DRIVER_DOC_URL="https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/fedora.html"

# DNF Packages (including script dependencies like git/unzip and Docker)
DNF_PACKAGES=(
    # Core & Downloading Tools
    "curl" "wget" "git" "unzip" "tar" "xz" "dnf-plugins-core"

    # Modern CLI Utilities
    "bat" # https://github.com/sharkdp/bat
    "eza" # https://github.com/eza-community/eza
    "fd-find" # https://github.com/sharkdp/fd
    "ripgrep" # https://github.com/burntsushi/ripgrep
    "fzf" # https://github.com/junegunn/fzf
    "zoxide" # https://github.com/ajeetdsouza/zoxide
    "jq" # https://github.com/stedolan/jq
    "direnv" # https://github.com/direnv/direnv

    # System & Process Monitor
    "btop" # https://github.com/aristocratos/btop
    "fastfetch" # https://github.com/LinusDierheimer/fastfetch
    "tmux" # https://github.com/tmux/tmux
    "stow" # https://www.gnu.org/software/stow/
    "ranger" # https://github.com/ranger/ranger

    # Terminal & Wayland Integration
    "foot" "wl-clipboard" "grim" "slurp"

    # Build Tools & Networking
    "make" "gcc" "gcc-c++" "bind-utils"

    # Docker Ecosystem
    # https://docs.docker.com/engine/install/fedora/
    "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"

    # NVIDIA Driver
    # https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/fedora.html
    "kernel-devel-matched" "kernel-headers" "cuda-drivers"
)

INSTALL_ZSH=false
INSTALL_FISH=false

# Flatpak Packages
readonly FLATPAK_PACKAGES=(
    "com.discordapp.Discord"
    "com.usebruno.Bruno"
    "md.obsidian.Obsidian"
)

# --- Colored Logging Functions ---
readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_YELLOW="\033[0;33m"
readonly COLOR_RED="\033[0;31m"

log() {
    local level="$1"; shift
    local color label
    case "$level" in
        INFO)    color="$COLOR_YELLOW"; label="INFO" ;;
        SUCCESS) color="$COLOR_GREEN";  label="SUCCESS" ;;
        ERROR)   color="$COLOR_RED";    label="ERROR" ;;
        *)       color="$COLOR_RESET";  label="$level" ;;
    esac
    printf "%b[%s] %s%b\n" "$color" "$label" "$*" "$COLOR_RESET"
}

log_info()    { log INFO "$*"; }
log_success() { log SUCCESS "$*"; }
log_error()   { log ERROR "$*"; }

# --- Installation Functions ---

remove_old_docker() {
    log_info "Removing old Docker packages, if they exist..."
    sudo dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine || true
    log_success "Old Docker packages (if any) were removed."
}

setup_repositories() {
    log_info "Configuring DNF repositories..."
    local docker_repo="/etc/yum.repos.d/docker-ce.repo"
    local nvidia_repo="/etc/yum.repos.d/cuda-fedora.repo"

    # Docker
    if [ ! -f "$docker_repo" ]; then
        log_info "Adding Docker repository..."
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager addrepo --from-repofile="$DOCKER_REPO_URL"
        log_success "Docker repository added."
    else
        log_info "Docker repository already exists."
    fi

    # NVIDIA
    if [ ! -f "$nvidia_repo" ]; then
        log_info "Adding NVIDIA CUDA repository..."
        local fedora_version arch repo_arch repo_url

        fedora_version=$(
            . /etc/os-release
            printf "%s" "${VERSION_ID:?}"
        )
        arch=$(uname -m)

        case "$arch" in
            x86_64)
                repo_arch="x86_64"
                ;;
            aarch64)
                repo_arch="sbsa"
                ;;
            *)
                log_error "Unsupported architecture for NVIDIA CUDA repository: $arch"
                return 1
                ;;
        esac

        repo_url="${NVIDIA_CUDA_REPO_BASE_URL}/fedora${fedora_version}/${repo_arch}/cuda-fedora${fedora_version}.repo"
        sudo dnf config-manager addrepo --from-repofile="$repo_url"
        sudo dnf clean expire-cache
        log_success "NVIDIA CUDA repository added."
    else
        log_info "NVIDIA CUDA repository already exists."
    fi

    log_info "Updating DNF cache..."
}

install_dnf_packages() {
    log_info "Installing DNF packages..."
    if sudo dnf install -y "${DNF_PACKAGES[@]}"; then
        log_success "All DNF packages were installed."
    else
        log_error "Failed to install one or more DNF packages."
    fi
}

install_flatpaks() {
    log_info "Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub "$FLATHUB_URL"

    log_info "Installing Flatpak packages..."
    if sudo flatpak install -y flathub "${FLATPAK_PACKAGES[@]}"; then
        log_success "All Flatpak packages were installed."
    else
        log_error "Failed to install one or more Flatpak packages."
    fi
}

setup_docker() {
    log_info "Configuring Docker service..."

    # Create the docker group if it doesn't exist
    sudo groupadd -f docker || true

    # Add the current user to the docker group
    sudo gpasswd -a "$USER" docker

    # Enable and restart the Docker daemon
    if sudo systemctl enable docker && sudo systemctl restart docker; then
        log_success "Docker enabled and user added to 'docker' group."
        log_info "To use Docker without sudo in your current session, run: newgrp docker"
        log_info "Otherwise, you can just log out and log back in."
    else
        log_error "Failed to enable or restart Docker service."
    fi
}

setup_zsh() {
    log_info "Configuring Zsh and Antidote (XDG)..."
    local zsh_path
    zsh_path=$(command -v zsh)

    local antidote_dir="${XDG_DATA_HOME}/antidote"

    if [ ! -d "$antidote_dir" ]; then
        log_info "Installing Antidote in $antidote_dir..."
        git clone --depth=1 "$ANTIDOTE_URL" "$antidote_dir"
        log_success "Antidote installed."
    else
        log_info "Antidote is already installed."
    fi

    if ! grep -qF "$zsh_path" /etc/shells; then
        log_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    else
        log_info "Zsh is already listed in /etc/shells."
    fi

    if [ "$SHELL" != "$zsh_path" ]; then
        log_info "Changing default shell to Zsh..."
        if sudo usermod -s "$zsh_path" "$USER"; then
            log_success "Shell changed to Zsh. (You may need to restart your session)"
        else
            log_error "Failed to change shell. Try manually with: sudo usermod -s $zsh_path $USER"
        fi
    else
        log_info "The default shell is already Zsh."
    fi
}

setup_fish() {
    log_info "Configuring Fish, Fisher and plugins..."
    local fish_path
    fish_path=$(command -v fish)

    if ! grep -qF "$fish_path" /etc/shells; then
        log_info "Adding $fish_path to /etc/shells"
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi

    if [ "$SHELL" != "$fish_path" ]; then
        log_info "Changing default shell to Fish..."
        if sudo usermod -s "$fish_path" "$USER"; then
            log_success "Shell changed to Fish. (You may need to restart your session)"
        else
            log_error "Failed to change shell. Try manually with: sudo usermod -s $fish_path $USER"
        fi
    else
        log_info "The default shell is already Fish."
    fi
}

setup_fish_plugins() {
    log_info "Installing Fisher and Fish plugins..."
    local fish_plugins="$HOME/.config/fish/fish_plugins"

    if [ ! -r "$fish_plugins" ]; then
        fish_plugins="$SCRIPT_DIR/.config/fish/fish_plugins"
    fi

    if [ ! -r "$fish_plugins" ]; then
        log_error "Manifest fish_plugins not found."
        return
    fi

    if fish -lc "functions -q fisher; or begin curl -sL $FISHER_URL | source; and fisher install jorgebucaran/fisher; end"; then
        log_success "Fisher installed."
    else
        log_error "Failed to install Fisher."
        return
    fi

    if fish -lc "fisher install (string match -rv '^\s*(#|$)' < '$fish_plugins')"; then
        log_success "Fish plugins installed."
    else
        log_error "Failed to install Fish plugins."
        return
    fi

    if fish -lc "functions -q tide; and tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time=No --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=Yes"; then
        log_success "Tide configured."
    else
        log_error "Failed to configure Tide or Tide is not installed."
    fi
}

setup_tmux_plugins() {
    log_info "Configuring tmux plugins..."
    local tmux_plugin_dir="${XDG_DATA_HOME}/tmux/plugins"
    local legacy_tmux_plugin_dir="$HOME/.tmux/plugins"
    local tpm_dir="$tmux_plugin_dir/tpm"

    if [ ! -d "$tmux_plugin_dir" ] && [ -d "$legacy_tmux_plugin_dir" ]; then
        log_info "Migrating tmux plugins to $tmux_plugin_dir..."
        mkdir -p "$(dirname "$tmux_plugin_dir")"
        mv "$legacy_tmux_plugin_dir" "$tmux_plugin_dir"
        rmdir "$HOME/.tmux" 2>/dev/null || true
    fi

    if [ ! -d "$tpm_dir" ]; then
        log_info "Installing TPM in $tpm_dir..."
        mkdir -p "$tmux_plugin_dir"
        git clone --depth=1 "$TPM_URL" "$tpm_dir"
        log_success "TPM installed."
    else
        log_info "TPM is already installed."
    fi

    if [ -x "$tpm_dir/bin/install_plugins" ]; then
        TMUX_PLUGIN_MANAGER_PATH="$tmux_plugin_dir" "$tpm_dir/bin/install_plugins"
        log_success "tmux plugins installed."
    else
        log_error "TPM install script not found at $tpm_dir/bin/install_plugins."
    fi
}

build_zsh_plugin_bundle() {
    log_info "Generating static Antidote bundle..."
    local antidote_script="${XDG_DATA_HOME}/antidote/antidote.zsh"
    local plugins_file="${XDG_CONFIG_HOME}/zsh/.zsh_plugins.txt"
    local bundle_file="${XDG_CACHE_HOME}/zsh/zsh_plugins.zsh"

    if [ ! -r "$antidote_script" ]; then
        log_error "Antidote not found in $antidote_script."
        return
    fi

    if [ ! -r "$plugins_file" ]; then
        plugins_file="$SCRIPT_DIR/.config/zsh/.zsh_plugins.txt"
    fi

    if [ ! -r "$plugins_file" ]; then
        log_error "Manifest .zsh_plugins.txt not found."
        return
    fi

    mkdir -p "$(dirname "$bundle_file")"
    if ANTIDOTE_HOME="${XDG_CACHE_HOME}/antidote" zsh -fc "source '$antidote_script'; antidote bundle < '$plugins_file' >| '$bundle_file'"; then
        log_success "Antidote bundle generated."
    else
        log_error "Failed to generate Antidote bundle."
    fi
}

install_fonts() {
    log_info "Installing Nerd Fonts ($FONT_NAME)..."
    local font_target_dir="$FONT_DIR/$FONT_NAME"

    # Remove previous installation to ensure cleanliness
    if [ -d "$font_target_dir" ]; then
        log_info "Removing previous installation..."
        rm -rf "$font_target_dir"
    fi

    mkdir -p "$font_target_dir"
    local tmp_zip="/tmp/${FONT_NAME}.zip"

    log_info "Downloading fonts from $FONT_URL..."
    if ! wget -q --show-progress -O "$tmp_zip" "$FONT_URL"; then
        log_error "Failed to download fonts."
        return 1
    fi

    log_info "Extracting fonts into $font_target_dir..."
    if ! unzip -q "$tmp_zip" -d "$font_target_dir"; then
        log_error "Failed to extract fonts."
        rm -f "$tmp_zip"
        return 1
    fi

    rm -f "$tmp_zip"

    # Remove unnecessary files (keep only .ttf and .otf)
    find "$font_target_dir" -type f ! \( -name '*.ttf' -o -name '*.otf' \) -delete

    # Count how many font files were installed
    local font_count
    font_count=$(find "$font_target_dir" -name '*.ttf' -o -name '*.otf' | wc -l)

    if [ "$font_count" -eq 0 ]; then
        log_error "No fonts were extracted. Check the URL."
        return 1
    fi

    log_info "Updating font cache..."
    fc-cache -fv "$font_target_dir" > /dev/null 2>&1

    log_success "Font $FONT_NAME installed ($font_count files)."
    log_info "Verifying installation..."

    # Verify if the font is available
    if fc-list | grep -qi "JetBrainsMono"; then
        log_success "Font JetBrainsMono confirmed on the system."
    else
        log_error "Font installed but not detected by fc-list. You may need to restart the terminal."
    fi
}

link_dotfiles() {
    log_info "Creating symlinks with 'stow'..."

    if ! command -v stow &> /dev/null; then
        log_error "'stow' not found. Skipping dotfiles linking."
        return
    fi

    remove_legacy_dotfile_links

    # Backup existing files that would cause conflicts
    local conflicts=(
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.config/zsh/.zshrc"
        "$HOME/.config/zsh/.zprofile"
        "$HOME/.config/zsh/.p10k.zsh"
        "$HOME/.config/zsh/.zsh_plugins.txt"
        "$HOME/.config/tmux/tmux.conf"
        "$HOME/.config/shell/xdg-env.sh"
        "$HOME/.config/maven/settings.xml"
        "$HOME/.config/fish/config.fish"
        "$HOME/.config/fish/fish_plugins"
        "$HOME/.config/fish/conf.d/xdg.fish"
        "$HOME/.config/foot"
        "$HOME/.config/ranger"
    )

    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local has_conflicts=false

    for file in "${conflicts[@]}"; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            if [ "$has_conflicts" = false ]; then
                log_info "Found conflicting files. Creating backup in $backup_dir..."
                mkdir -p "$backup_dir"
                has_conflicts=true
            fi
            log_info "Moving $(basename "$file") to backup..."
            mv "$file" "$backup_dir/"
        fi
    done

    if stow --no-folding --verbose=1 -d "$SCRIPT_DIR" -t "$HOME" .; then
        log_success "Dotfiles linked."
        if [ "$has_conflicts" = true ]; then
            log_info "Original files saved in: $backup_dir"
        fi
    else
        log_error "Failed to link dotfiles with 'stow'."
    fi
}

remove_legacy_dotfile_links() {
    local legacy_links=(
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "$HOME/.zsh_plugins.txt"
        "$HOME/.tmux.conf"
        "$HOME/xdg-env.sh"
    )

    for file in "${legacy_links[@]}"; do
        if [ -L "$file" ]; then
            local target
            target=$(readlink "$file")
            case "$target" in
                "$SCRIPT_DIR"/*|.dotfiles/*)
                    log_info "Removing legacy symlink $file -> $target"
                    rm "$file"
                    ;;
            esac
        fi
    done

    for file in "$HOME"/.zcompdump*; do
        if [ -f "$file" ]; then
            log_info "Removing legacy zcompdump $file"
            rm "$file"
        fi
    done
}

final_cleanup() {
    log_info "Cleaning DNF cache..."
    sudo dnf autoremove -y
    sudo dnf clean all
    log_success "Cleanup completed."
}

prompt_shell_choice() {
    log_info "Which shell do you want to install and configure?"
    echo "1) Fish (recommended/default)"
    echo "2) Zsh"
    echo "3) Both"
    echo "4) None"
    read -rp "Choose an option [1]: " shell_choice

    case "${shell_choice:-1}" in
        1)
            DNF_PACKAGES+=("fish")
            INSTALL_FISH=true
            ;;
        2)
            DNF_PACKAGES+=("zsh")
            INSTALL_ZSH=true
            ;;
        3)
            DNF_PACKAGES+=("fish" "zsh")
            INSTALL_FISH=true
            INSTALL_ZSH=true
            ;;
        4)
            log_info "No shell will be installed."
            ;;
        *)
            log_error "Invalid option. Assuming Fish."
            DNF_PACKAGES+=("fish")
            INSTALL_FISH=true
            ;;
    esac
}

# --- Main Function ---
main() {
    log_info "Starting Fedora system configuration (XDG)..."

    sudo -v

    prompt_shell_choice

    remove_old_docker
    setup_repositories
    install_dnf_packages
    install_flatpaks
    setup_docker

    if [ "$INSTALL_ZSH" = true ]; then
        setup_zsh
    fi

    if [ "$INSTALL_FISH" = true ]; then
        setup_fish
    fi

    install_fonts
    link_dotfiles
    setup_tmux_plugins

    if [ "$INSTALL_ZSH" = true ]; then
        build_zsh_plugin_bundle
    fi

    if [ "$INSTALL_FISH" = true ]; then
        setup_fish_plugins
    fi

    final_cleanup

    log_success "Configuration complete! Restart your session to apply all changes (shell, Docker group and NVIDIA driver)."
}

# Call main function
main
