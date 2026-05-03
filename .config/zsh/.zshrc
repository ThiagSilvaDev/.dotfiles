# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# XDG Base Directory Specification
# export HISTFILE="$XDG_STATE_HOME"/zsh/history
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "${HISTFILE:h}"  # :h extracts the directory path

# Plugin manager
export ANTIDOTE_HOME="$XDG_CACHE_HOME/antidote"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
zsh_plugins_static="$XDG_CACHE_HOME/zsh/zsh_plugins.zsh"
zsh_antidote="$XDG_DATA_HOME/antidote/antidote.zsh"

if [[ -r "$zsh_antidote" ]]; then
  source "$zsh_antidote"
  if [[ -r "$zsh_plugins" && ! "$zsh_plugins_static" -nt "$zsh_plugins" ]]; then
    mkdir -p "${zsh_plugins_static:h}"
    antidote bundle < "$zsh_plugins" >| "$zsh_plugins_static"
  fi
  [[ -r "$zsh_plugins_static" ]] && source "$zsh_plugins_static"
else
  print -u2 "antidote not found at $zsh_antidote"
fi

unset zsh_plugins zsh_plugins_static zsh_antidote

autoload -Uz promptinit
promptinit
if (( $+functions[prompt_powerlevel10k_setup] )); then
  prompt powerlevel10k
fi

autoload -Uz compinit
if ! (( $+functions[compdef] )); then
  if [[ -f "$ZSH_COMPDUMP" ]]; then
    compinit -C -d "$ZSH_COMPDUMP"
  else
    compinit -d "$ZSH_COMPDUMP"
  fi
fi

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# User configuration
alias zshconfig="nano ${ZDOTDIR:-$HOME}/.zshrc"
alias astro="nocorrect astro"
alias mvn='mvn -gs "$XDG_CONFIG_HOME/maven/settings.xml"'
alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'
alias d='docker'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"' # Lista formatada e limpa
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dex='docker exec -it' # Uso: dex <container_id> /bin/bash
alias dlog='docker logs -f --tail 100' # Acompanha as últimas 100 linhas de log

# Docker Compose - Orquestração de Infraestrutura
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'

# Docker - Limpeza e Manutenção
alias dstop='docker stop $(docker ps -q)'
alias drmc='docker rm $(docker ps -a -q)' # Remove todos os containers parados
alias drmi='docker rmi $(docker images -f "dangling=true" -q)' # Remove imagens sem tag (<none>)
alias dprune='docker system prune -af --volumes' # Limpeza profunda (containers, redes, imagens e volumes ociosos)

# To customize prompt, run `p10k configure` or edit ${ZDOTDIR:-~}/.p10k.zsh.
[[ ! -f ${ZDOTDIR:-~}/.p10k.zsh ]] || source ${ZDOTDIR:-~}/.p10k.zsh

# Set up fzf key bindings and fuzzy completion
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

# Load Angular CLI autocompletion.
if command -v ng &> /dev/null; then
  source <(ng completion script)
fi

source "$XDG_CONFIG_HOME/shell/xdg-env.sh"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# bun
export PATH="$BUN_INSTALL/bin:$PATH"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=("$HOME/.juliaup/bin" $path)
export PATH

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# <<< juliaup initialize <<<

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
