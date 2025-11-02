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
    "curl" "wget" "zsh" "tmux" "btop" "stow" "fzf" "ripgrep" "ranger"
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

# --- Funções de Instalação ---

setup_repositories() {
    log_info "Configurando repositórios DNF..."
    local docker_repo="/etc/yum.repos.d/docker-ce.repo"

    # Docker
    if [ ! -f "$docker_repo" ]; then
        log_info "Adicionando repositório do Docker..."
        sudo dnf -y install dnf-plugins-core
        sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        log_success "Repositório Docker adicionado."
    else
        log_info "Repositório Docker já existe."
    fi

    log_info "Atualizando cache do DNF..."
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

setup_zsh() {
    log_info "Configurando Zsh, Oh My Zsh (XDG) e plugins..."
    local zsh_path
    zsh_path=$(which zsh)

    # Define os caminhos XDG para o Oh My Zsh
    local omz_dir="${XDG_DATA_HOME}/oh-my-zsh"
    local omz_custom="${XDG_CONFIG_HOME}/oh-my-zsh/custom"

    # Instala Oh My Zsh
    if [ ! -d "$omz_dir" ]; then
        log_info "Instalando Oh My Zsh em $omz_dir..."

        # Baixa o instalador
        local installer="/tmp/omz_install.sh"
        curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"

        # Instala com variáveis de ambiente corretas
        RUNZSH=no ZSH="$omz_dir" sh "$installer" --unattended

        rm -f "$installer"
        log_success "Oh My Zsh instalado."
    else
        log_info "Oh My Zsh já está instalado."
    fi

    # Cria o diretório custom se não existir
    mkdir -p "$omz_custom/plugins"
    mkdir -p "$omz_custom/themes"

    # Plugin: zsh-autosuggestions
    if [ ! -d "$omz_custom/plugins/zsh-autosuggestions" ]; then
        log_info "Instalando zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$omz_custom/plugins/zsh-autosuggestions"
    else
        log_info "Plugin zsh-autosuggestions já existe."
    fi

    # Plugin: zsh-syntax-highlighting
    if [ ! -d "$omz_custom/plugins/zsh-syntax-highlighting" ]; then
        log_info "Instalando zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$omz_custom/plugins/zsh-syntax-highlighting"
    else
        log_info "Plugin zsh-syntax-highlighting já existe."
    fi

    # Tema: Powerlevel10k
    if [ ! -d "$omz_custom/themes/powerlevel10k" ]; then
        log_info "Instalando tema Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz_custom/themes/powerlevel10k"
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

    # Remove instalação anterior para garantir limpeza
    if [ -d "$font_target_dir" ]; then
        log_info "Removendo instalação anterior..."
        rm -rf "$font_target_dir"
    fi

    mkdir -p "$font_target_dir"
    local tmp_zip="/tmp/${FONT_NAME}.zip"

    log_info "Baixando fontes de $FONT_URL..."
    if ! wget -q --show-progress -O "$tmp_zip" "$FONT_URL"; then
        log_error "Falha ao baixar as fontes."
        return 1
    fi

    log_info "Extraindo fontes em $font_target_dir..."
    if ! unzip -q "$tmp_zip" -d "$font_target_dir"; then
        log_error "Falha ao extrair as fontes."
        rm -f "$tmp_zip"
        return 1
    fi

    rm -f "$tmp_zip"

    # Remove arquivos desnecessários (apenas mantém .ttf e .otf)
    find "$font_target_dir" -type f ! \( -name '*.ttf' -o -name '*.otf' \) -delete

    # Conta quantos arquivos de fonte foram instalados
    local font_count
    font_count=$(find "$font_target_dir" -name '*.ttf' -o -name '*.otf' | wc -l)

    if [ "$font_count" -eq 0 ]; then
        log_error "Nenhuma fonte foi extraída. Verifique a URL."
        return 1
    fi

    log_info "Atualizando cache de fontes..."
    fc-cache -fv "$font_target_dir" > /dev/null 2>&1

    log_success "Fonte $FONT_NAME instalada ($font_count arquivos)."
    log_info "Verificando instalação..."

    # Verifica se a fonte está disponível
    if fc-list | grep -qi "JetBrainsMono"; then
        log_success "Fonte JetBrainsMono confirmada no sistema."
        log_info "Configure seu terminal para usar: 'JetBrainsMono Nerd Font' ou 'JetBrainsMonoNL Nerd Font Mono'"
    else
        log_error "Fonte instalada mas não detectada pelo fc-list. Pode ser necessário reiniciar o terminal."
    fi
}

link_dotfiles() {
    log_info "Criando links simbólicos com 'stow'..."

    if ! command -v stow &> /dev/null; then
        log_error "'stow' não encontrado. Pulando link de dotfiles."
        return
    fi

    # Backup de arquivos existentes que causariam conflito
    local conflicts=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/foot"
        "$HOME/.config/ranger"
    )

    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local has_conflicts=false

    for file in "${conflicts[@]}"; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            if [ "$has_conflicts" = false ]; then
                log_info "Encontrados arquivos conflitantes. Criando backup em $backup_dir..."
                mkdir -p "$backup_dir"
                has_conflicts=true
            fi
            log_info "Movendo $(basename "$file") para backup..."
            mv "$file" "$backup_dir/"
        fi
    done

    if stow --verbose=1 .; then
        log_success "Dotfiles linkados."
        if [ "$has_conflicts" = true ]; then
            log_info "Arquivos originais salvos em: $backup_dir"
        fi
    else
        log_error "Falha ao linkar dotfiles com 'stow'."
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
    setup_zsh
    install_fonts
    link_dotfiles
    final_cleanup

    log_success "Configuração concluída! Reinicie sua sessão para aplicar todas as mudanças (shell e grupo Docker)."
}

# Chama a função principal
main
