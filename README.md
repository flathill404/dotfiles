# dotfiles

Personal dotfiles for macOS (Apple Silicon). One-command setup.

## Quick Start

```bash
git clone https://github.com/flathill404/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/setup.sh
```

## What Gets Installed

- **Shell**: zsh with starship prompt, autosuggestions, syntax highlighting
- **Terminal**: Ghostty with VS Code Dark theme
- **Editor**: Visual Studio Code with curated extensions
- **Containers**: Docker via Colima
- **Languages**: Node.js, pnpm, Python via [proto](https://moonrepo.dev/proto)
- **Tools**: git, git-lfs, gnupg, jq, tmux, stow

## Structure

| Directory   | Target                                  | Description              |
| ----------- | --------------------------------------- | ------------------------ |
| `zsh/`      | `~/`                                    | Zsh shell configuration  |
| `git/`      | `~/`                                    | Git config & global ignore |
| `tmux/`     | `~/`                                    | Tmux configuration       |
| `starship/` | `~/.config/`                            | Starship prompt          |
| `ghostty/`  | `~/.config/`                            | Ghostty terminal         |
| `brew/`     | `~/`                                    | Homebrew Brewfile        |
| `proto/`    | `~/`                                    | Proto language manager   |
| `vscode/`   | `~/Library/Application Support/Code/User` | VS Code settings       |

Symlinks are managed by [GNU Stow](https://www.gnu.org/software/stow/).

## Font

FiraMono Nerd Font — installed automatically via Homebrew.

## After Setup

1. Import your GPG private key for git commit signing
2. Create `~/.gitconfig.local` for machine-specific git settings (e.g. work email)
