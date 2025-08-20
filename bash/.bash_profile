# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    export PATH="$HOME/bin:$PATH"
fi

# set proto PATH if it exists
if [ -d "$HOME/.proto" ]; then
    export PROTO_HOME="$HOME/.proto";
    export PATH="$HOME/.proto/shims:$HOME/.proto/bin:$PATH"
fi
