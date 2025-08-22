# dotfiles

flathill404's dotfiles!

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

```bash
cat vscode/extensions.json | jq ".recommendations[]" | xargs -I{} code --install-extension {}
```

### install settings

The location of the user-level settings.json file for vscode depends on the OS.

| OS      |                                                           |
| ------- | --------------------------------------------------------- |
| Windows | %APPDATA%\Code\User\settings.json                         |
| macOS   | $HOME/Library/Application Support/Code/User/settings.json |
| Linux   | $HOME/.config/Code/User/settings.json                     |

#### Linux / WSL

```bash
stow vscode --target="$HOME/.config/Code/User"
```

#### macOS

```bash
stow vscode --target="$HOME/Library/Application Support/Code/User"
```
