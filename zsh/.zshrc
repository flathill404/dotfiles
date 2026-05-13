# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       HIST_VERIFY HIST_NO_STORE HIST_EXPIRE_DUPS_FIRST \
       APPEND_HISTORY SHARE_HISTORY

# Prevent secrets from being saved to history file.
# Returns 2 → save to in-memory history but NOT to $HISTFILE.
zshaddhistory() {
  local line="${1%%$'\n'}"
  local lower="${line:l}"  # case-insensitive matching
  # Generic credential patterns (case-insensitive)
  case "$lower" in
    *api_key*|*apikey*|*secret*|*token*|*password*|*passwd*|*aws_secret*) return 2 ;;
    *"bearer "*|*"authorization: "*) return 2 ;;
    *" -p"[!-]*|*"--password="*) return 2 ;;  # mysql/postgres inline passwords
  esac
  # Provider-specific token prefixes (case-sensitive — these are exact)
  case "$line" in
    *ghp_*|*gho_*|*ghu_*|*ghs_*|*ghr_*|*github_pat_*) return 2 ;;  # GitHub
    *sk-ant-*|*sk-proj-*|*sk-*) return 2 ;;                         # Anthropic / OpenAI
    *xox[abposr]-*) return 2 ;;                                     # Slack
    *AKIA[0-9A-Z][0-9A-Z]*) return 2 ;;                             # AWS access key
    *AIza[0-9A-Za-z_-]*) return 2 ;;                                # Google API key
  esac
  return 0
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

# ── Plugins (Homebrew on macOS, apt on Linux) ────────────────────────────────
# zsh-syntax-highlighting must be sourced AFTER autosuggestions
for _plugin in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -f $_plugin ]] && source $_plugin && break
done
for _plugin in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -f $_plugin ]] && source $_plugin && break
done
unset _plugin

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

# Debian/Ubuntu rename bat → batcat, fd → fdfind. Bridge to the canonical names.
if (( ! $+commands[bat] )) && (( $+commands[batcat] )); then
  alias bat='batcat'
fi
if (( ! $+commands[fd] )) && (( $+commands[fdfind] )); then
  alias fd='fdfind'
fi

if (( $+commands[bat] )) || (( $+commands[batcat] )); then
  local _bat="${commands[bat]:-${commands[batcat]}}"
  alias cat="$_bat --paging=never"
  export MANPAGER="sh -c 'col -bx | $_bat -l man -p'"
  unset _bat
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
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz|*.txz)   tar xJf "$1" ;;
    *.tar.zst)        tar --use-compress-program=unzstd -xf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zst)            zstd -d "$1" ;;
    *.zip)            unzip "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x "$1" ;;
    *)                echo "Unknown archive: $1" ;;
  esac
}

# Get public IP address (HTTPS-only, no redirect-followed plaintext fallback)
myip() {
  curl -fsS https://api.ipify.org || curl -fsS https://ifconfig.me
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
