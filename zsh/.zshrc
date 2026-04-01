# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       HIST_VERIFY HIST_NO_STORE HIST_EXPIRE_DUPS_FIRST \
       APPEND_HISTORY SHARE_HISTORY

# Prevent secrets from being saved to history file
zshaddhistory() {
  local line="${1%%$'\n'}"
  [[ "$line" != *"API_KEY"* && "$line" != *"SECRET"* && \
     "$line" != *"TOKEN"* && "$line" != *"PASSWORD"* && \
     "$line" != *"aws_secret"* && "$line" != *"Bearer "* ]] && return 0
  return 2  # save to internal history but NOT to HISTFILE
}

# ── Options ──────────────────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt CORRECT NO_BEEP
setopt INTERACTIVE_COMMENTS EXTENDED_GLOB GLOB_DOTS

# ── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit
if [[ -n "${XDG_CACHE_HOME}/zsh/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"
else
  compinit -C -d "${XDG_CACHE_HOME}/zsh/zcompdump"
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# ── Plugins (via Homebrew — hardcoded path for performance) ──────────────────
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Key Bindings ─────────────────────────────────────────────────────────────
bindkey -e
bindkey '^[[1;3C' forward-word       # Alt+Right
bindkey '^[[1;3D' backward-word      # Alt+Left
bindkey '^[[3~'   delete-char        # Delete key
bindkey '^U'      backward-kill-line
bindkey '^K'      kill-line

# ── Modern CLI Aliases ───────────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons'
  alias l='eza -a --icons --group-directories-first'
else
  alias ls='ls -G'
  alias la='ls -AF'
  alias ll='ls -Al'
  alias l='ls -A'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

alias grep='grep --color=auto'
alias sl='ls'

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

# ── Functions ────────────────────────────────────────────────────────────────

# mkdir + cd in one
mkcd() { mkdir -p "$1" && cd "$1" }

# Backup a file with timestamp
buf() {
  local filename="${1:?}" filetime
  filetime=$(date +%Y%m%d_%H%M%S)
  cp -a "${filename}" "${filename}_${filetime}"
}

# Extract any archive
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.7z)      7z x "$1" ;;
    *.zst)     zstd -d "$1" ;;
    *)         echo "Unknown archive: $1" ;;
  esac
}

# Get public IP address
myip() {
  curl -s http://myip.dnsomatic.com/ || curl -s http://checkip.dyndns.com/ | grep -Eo '[0-9.]+'
}

# Quick port lookup
port() { lsof -i :"$1" }

# ── Tool Integrations ────────────────────────────────────────────────────────

# fzf (fuzzy finder keybindings: Ctrl-R history, Ctrl-T files, Alt-C cd)
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# zoxide (smarter cd — use `z` command)
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# direnv (auto-load .envrc per directory)
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# ── Prompt ───────────────────────────────────────────────────────────────────
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
