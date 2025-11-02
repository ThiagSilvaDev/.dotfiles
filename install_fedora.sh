#!/usr/bin/env bash
#
# Script de configuração pessoal para Fedora (compatível com XDG).
#
# Instala arquivos de sistema em /etc, dados em .local/share
# e configurações em .config.
#

set -euo pipefail

# --- Constantes XDG e Configurações ---
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

readonly FONT_DIR="${XDG_DATA_HOME}/fonts"
readonly FONT_NAME="JetBrainsMono"
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip"

# Pacotes DNF (incluindo dependências do script como git/unzip e do Docker)
readonly DNF_PACKAGES=(
    "curl" "wget" "zsh" "tmux" "btop" "stow" "fzf" "ripgrep"
    "fastfetch" "foot" "bat" "git" "unzip" "dnf-plugins-core"
    "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin"
    "docker-compose-plugin"
)

# Pacotes Flatpak
readonly FLATPAK_PACKAGES=(
    "com.discordapp.Discord"
    "com.usebruno.Bruno"
    "md.obsidian.Obsidian"
)

# --- Funções de Log com Cores ---
readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_YELLOW="\033[0;33m"
readonly COLOR_RED="\033[0;31m"

log_info() {
    echo -e "${COLOR_YELLOW}[INFO] $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS] $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}"
}

# --- Funções de Instalação ---

setup_repositories() {
    log_info "Configurando repositórios DNF..."
    local docker_repo="/etc/yum.repos.d/docker-ce.repo"

    # Docker
    if [ ! -f "$docker_repo" ]; then
        log_info "Adicionando repositório do Docker..."
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        log_success "Repositório Docker adicionado."
    else
        log_info "Repositório Docker já existe."
    fi

    log_info "Atualizando cache do DNF..."
    sudo dnf check-update
}

install_dnf_packages() {
    log_info "Instalando pacotes DNF..."
    if sudo dnf install -y "${DNF_PACKAGES[@]}"; then
        log_success "Todos os pacotes DNF foram instalados."
    else
        log_error "Falha ao instalar um ou mais pacotes DNF."
    fi
}

install_flatpaks() {
    log_info "Instalando pacotes Flatpak..."
    if flatpak install -y flathub "${FLATPAK_PACKAGES[@]}"; then
        log_success "Todos os Flatpaks foram instalados."
    else
        log_error "Falha ao instalar um ou mais Flatpaks."
    fi
}

setup_docker() {
    log_info "Configurando o serviço Docker..."
    if sudo systemctl enable --now docker; then
        sudo usermod -aG docker "$USER"
        log_success "Docker ativado e usuário adicionado ao grupo 'docker'."
        log_info "Lembre-se de sair e logar novamente para que a mudança de grupo tenha efeito."
    else
        log_error "Falha ao ativar o serviço Docker."
    fi
}

# NOVO: Define ZDOTDIR para que o zsh use o diretório XDG
setup_zsh_environment() {
    log_info "Configurando ambiente Zsh (ZDOTDIR)..."
    local zshenv_file="$HOME/.zshenv"
    # Este é o caminho padrão XDG para configs do zsh
    local zdotdir_line="export ZDOTDIR=\"${XDG_CONFIG_HOME}/zsh\""

    # .zshenv é lido antes do .zshrc, sendo o local ideal para definir ZDOTDIR
    if ! grep -qF "$zdotdir_line" "$zshenv_file" 2>/dev/null; then
        log_info "Adicionando ZDOTDIR ao $zshenv_file..."
        echo -e "\n# Define o diretório de configuração do Zsh (XDG)\n$zdotdir_line" >> "$zshenv_file"
        log_success "$zshenv_file atualizado."
    else
        log_info "$zshenv_file já está configurado."
    fi
}

# MODIFICADO: Instala o Oh My Zsh nos caminhos XDG
setup_zsh() {
    log_info "Configurando Zsh, Oh My Zsh (XDG) e plugins..."
    local zsh_path
    zsh_path=$(which zsh)

    # Define os caminhos XDG para o Oh My Zsh
    # $ZSH -> Onde o Oh My Zsh será instalado (dados)
    # $ZSH_CUSTOM -> Onde os plugins e temas customizados ficarão (config)
    export ZSH="${XDG_DATA_HOME}/oh-my-zsh"
    export ZSH_CUSTOM="${XDG_CONFIG_HOME}/oh-my-zsh/custom"

    # Instala Oh My Zsh
    if [ ! -d "$ZSH" ]; then
        log_info "Instalando Oh My Zsh em $ZSH..."
        # Passamos ZSH e ZSH_CUSTOM como variáveis de ambiente para o instalador
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh instalado."
    else
        log_info "Oh My Zsh já está instalado."
    fi

    # Define os caminhos de plugins e temas baseados em ZSH_CUSTOM
    local custom_plugins="${ZSH_CUSTOM}/plugins"
    local custom_themes="${ZSH_CUSTOM}/themes"

    # Garante que os diretórios customizados existam
    mkdir -p "$custom_plugins"
    mkdir -p "$custom_themes"

    # Plugin: zsh-autosuggestions
    if [ ! -d "$custom_plugins/zsh-autosuggestions" ]; then
        log_info "Instalando zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    else
        log_info "Plugin zsh-autosuggestions já existe."
    fi

    # Plugin: zsh-syntax-highlighting
    if [ ! -d "$custom_plugins/zsh-syntax-highlighting" ]; then
        log_info "Instalando zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins/zsh-syntax-highlighting"
    else
        log_info "Plugin zsh-syntax-highlighting já existe."
    fi

    # Tema: Powerlevel10k
    if [ ! -d "$custom_themes/powerlevel10k" ]; then
        log_info "Instalando tema Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom_themes/powerlevel10k"
    else
        log_info "Tema Powerlevel10k já existe."
    fi

    # Mudar o shell padrão (de forma robusta)
    if [ "$SHELL" != "$zsh_path" ]; then
        log_info "Alterando o shell padrão para Zsh..."
        if ! grep -qF "$zsh_path" /etc/shells; then
            log_info "Adicionando $zsh_path ao /etc/shells"
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi

        if sudo usermod -s "$zsh_path" "$USER"; then
            log_success "Shell alterado para Zsh. (Pode ser necessário reiniciar a sessão)"
        else
            log_error "Falha ao alterar o shell. Tente manualmente com: sudo usermod -s $zsh_path $USER"
        fi
    else
        log_info "O shell padrão já é Zsh."
    fi
}

install_fonts() {
    log_info "Instalando Nerd Fonts ($FONT_NAME)..."
    local font_target_dir="$FONT_DIR/$FONT_NAME"

    if [ ! -d "$font_target_dir" ]; then
        mkdir -p "$font_target_dir"
        local tmp_zip="/tmp/${FONT_NAME}.zip"

        log_info "Baixando fontes..."
        wget -O "$tmp_zip" "$FONT_URL"

        log_info "Extraindo fontes..."
        unzip -q "$tmp_zip" -d "$font_target_dir"

        rm "$tmp_zip"

        log_info "Atualizando cache de fontes..."
        fc-cache -fv
        log_success "Fonte $FONT_NAME instalada."
    else
        log_info "Fonte $FONT_NAME já parece estar instalada."
    fi
}

link_dotfiles() {
    log_info "Criando links simbólicos com 'stow'..."
    # Este comando 'stow .' assume que seu repositório está estruturado
    # para espelhar o $HOME, contendo pastas como '.config', '.local', etc.
    if command -v stow &> /dev/null; then
        if stow .; then
            log_success "Dotfiles linkados."
        else
            log_error "Falha ao linkar dotfiles com 'stow'."
        fi
    else
        log_error "'stow' não encontrado. Pulando link de dotfiles."
    fi
}

final_cleanup() {
    log_info "Limpando cache do DNF..."
    sudo dnf autoremove -y
    sudo dnf clean all
    log_success "Limpeza concluída."
}

# --- Função Principal ---
main() {
    log_info "Iniciando configuração do sistema Fedora (XDG)..."

    sudo -v

    setup_repositories
    install_dnf_packages
    install_flatpaks
    setup_docker
    setup_zsh_environment # NOVO: Deve vir antes de setup_zsh
    setup_zsh
    install_fonts
    link_dotfiles
    final_cleanup

    log_success "Configuração concluída! Reinicie sua sessão para aplicar todas as mudanças (shell e grupo Docker)."
}

# Chama a função principal
main
