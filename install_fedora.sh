#!/usr/bin/env bash
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"

PACKAGES=(
    "curl"
    "wget"
    "neovim"
    "zsh"
    "tmux"
    "btop"
    "stow"
    "fzf"
    "ripgrep"
    "fastfetch"
    "foot"
    "code"
    "bat"
)

# VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

dnf check-update

install_packages() {
    local packages=("$@")
    echo "Instalando pacotes: ${packages[*]}"

    for package in "${packages[@]}"; do
        if sudo dnf install -y "$package"; then
            echo "✓ $package instalado com sucesso"
        else
            echo "✗ Falha ao instalar $package"
        fi
    done
}

install_packages "${PACKAGES[@]}"

FLATPAK_PACKAGES=(
    "com.discordapp.Discord"
    "com.usebruno.Bruno"
    "md.obsidian.Obsidian"
)

install_flatpaks() {
    local packages=("$@")
    echo "Instalando Flatpaks: ${packages[*]}"

    for package in "${packages[@]}"; do
        if flatpak install -y flathub "$package"; then
            echo "✓ $package instalado com sucesso"
        else
            echo "✗ Falha ao instalar $package"
        fi
    done
}

install_flatpaks "${FLATPAK_PACKAGES[@]}"


# Docker install
echo "Docker install"

sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

DOCKER_PACKAGES=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
)

install_packages "${DOCKER_PACKAGES[@]}"

sudo systemctl enable --now docker

# ZSH, Oh My Zshell
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

chsh -s "$(which zsh)"

# JetBrains font
wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
unzip /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono/"

fc-cache -fv


# Create symlink with gnu stow
stow .

echo "Limpando cache"
sudo dnf autoremove -y
sudo dnf clean all

echo "Configuração concluída"
