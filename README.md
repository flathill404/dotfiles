# dotfiles

flathill404's dotfiles!

## fonts

| font family        | URL                                                                        | use              |
| ------------------ | -------------------------------------------------------------------------- | ---------------- |
| FiraMono Nerd Font | https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraMono | editor, terminal |

## stow install

```bash
stow bash
stow git
stow alacritty
stow starship
stow tmux

# Ubuntu
stow xmodmap
```

## vscode

### install extensions

#### Linux / macOS

```bash
cat vscode/extensions.json | jq ".recommendations[]" | xargs -I{} code --install-extension {}
```

#### Windows

```bash
(☝︎ ՞ਊ ՞)☝︎
```

### install settings

The location of the user-level settings.json file for vscode depends on the OS.

| OS              |                                                           |
| --------------- | --------------------------------------------------------- |
| Linux           | $HOME/.config/Code/User/settings.json                     |
| Windows(Native) | %APPDATA%\Code\User\settings.json                         |
| Windows(WSL)    | $HOME/.vscode-server/data/Machine/settings.json           |
| macOS           | $HOME/Library/Application Support/Code/User/settings.json |

#### Linux

```bash
stow vscode --target="$HOME/.config/Code/User"
```

#### Windows(WSL)

```bash
stow vscode --target="$HOME/.vscode-server/data/Machine"
```

#### macOS

```bash
stow vscode --target="$HOME/Library/Application Support/Code/User"
```
