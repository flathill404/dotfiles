# -- History --
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY

# -- Completion --
autoload -Uz compinit && compinit

# -- Plugins (via Homebrew) --
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# -- Aliases --

# ls (macOS ls -G for color)
alias ls='ls -G'
alias sl='ls'
alias la='ls -AF'
alias ll='ls -Al'
alias l='ls -A'
alias l1='ls -1'
alias lf='ls -F'

# grep
alias grep='grep --color=auto'

# Docker
alias dk='docker'
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dki='docker images'
alias dkip='docker image prune -a -f'
alias dkvp='docker volume prune -f'
alias dksp='docker system prune -a -f'
alias dkex='docker exec -it'
alias dkrit='docker run --rm -it'

# Docker Compose
alias dco='docker compose'
alias dcol='docker compose logs -f --tail 100'
alias dcou='docker compose up'

# -- Functions --

# Backup a file with timestamp
buf() {
  local filename="${1:?}" filetime
  filetime=$(date +%Y%m%d_%H%M%S)
  cp -a "${filename}" "${filename}_${filetime}"
}

# Get public IP address
myip() {
  curl -s http://myip.dnsomatic.com/ || curl -s http://checkip.dyndns.com/ | grep -Eo '[0-9.]+'
}

# -- Prompt --
eval "$(starship init zsh)"
