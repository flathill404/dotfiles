# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# User bin directories
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Proto (language version manager)
if [[ -d "$HOME/.proto" ]]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# Cargo / Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$PATH:$HOME/go/bin"
