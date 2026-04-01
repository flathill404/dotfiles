# ── XDG Base Directory ───────────────────────────────────────────────────────
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ── Homebrew (Apple Silicon) ─────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── User bin directories ─────────────────────────────────────────────────────
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ── Proto (language version manager) ─────────────────────────────────────────
if [[ -d "$HOME/.proto" ]]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# ── Cargo / Rust ─────────────────────────────────────────────────────────────
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ── Go ───────────────────────────────────────────────────────────────────────
[[ -d "$HOME/go/bin" ]] && export PATH="$PATH:$HOME/go/bin"

# ── Security ─────────────────────────────────────────────────────────────────
umask 077
