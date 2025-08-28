# macOS
if [[ "$(uname)" = "Darwin" ]]; then
    # activate homebrew
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# run xmodmap .Xmodmap if it exists
if [ -f "$HOME/.Xmodmap" ]; then
    xmodmap "$HOME/.Xmodmap"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# set proto PATH if it exists
if [ -d "$HOME/.proto" ]; then
    export PROTO_HOME="$HOME/.proto";
    export PATH="$HOME/.proto/shims:$HOME/.proto/bin:$PATH"
fi
