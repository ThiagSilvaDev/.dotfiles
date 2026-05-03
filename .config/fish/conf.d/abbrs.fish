# https://github.com/eza-community/eza
abbr -a ls "eza --icons"

abbr -a fishconfig "code ~/.config/fish/config.fish"
abbr -a mvn 'mvn -gs "$XDG_CONFIG_HOME/maven/settings.xml"'
abbr -a nvidia-settings 'nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'

# --- Docker  ---
abbr -a d "docker"
abbr -a dps 'docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
abbr -a dpsa "docker ps -a"
abbr -a dimg "docker images"
abbr -a dex "docker exec -it"
abbr -a dlog "docker logs -f --tail 100"

# --- Docker Compose ---
abbr -a dc "docker compose"
abbr -a dcu "docker compose up -d"
abbr -a dcd "docker compose down"
abbr -a dcr "docker compose restart"
abbr -a dcl "docker compose logs -f"

# --- Docker Cleanup ---
abbr -a dstop "docker ps -q | xargs -r docker stop"
abbr -a drmc "docker ps -aq | xargs -r docker rm"
abbr -a drmi "docker images -f 'dangling=true' -q | xargs -r docker rmi"
abbr -a dprune "docker system prune -af --volumes"

abbr -a wget 'wget --hsts-file="$XDG_STATE_HOME/wget-hsts"'
