# dotfiles

flathill404's dotfiles!

## Fonts

| font family        | URL                                                                        | use              |
| ------------------ | -------------------------------------------------------------------------- | ---------------- |
| FiraMono Nerd Font | https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraMono | editor, terminal |

## GNU Stow

https://www.gnu.org/software/stow/

### Linux / macOS
```bash
stow bash
stow git
stow alacritty
stow starship
stow tmux
stow zed
```

### Linux
```bash
stow xmodmap
```

### macOS
```bash
stow brew
```

## Visual Studio Code

https://code.visualstudio.com/

### install extensions

#### Linux / macOS

```bash
cat vscode/extensions.json | jq ".recommendations[]" | xargs -I{} code --install-extension {}
```

#### Windows

```bash
(☝︎ ՞ਊ ՞)☝︎
```
open this repository on vscode, and install extensions from gui 😭

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

## Homebrew

https://brew.sh/

### install brew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### install packages

```bash
brew bundle --global
```
