# dotfiles

Personal dotfiles for macOS (Apple Silicon). One-command setup for a fresh MacBook Pro.

## Quick Start

```bash
git clone https://github.com/flathill404/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/setup.sh
```

The setup script is idempotent — safe to run multiple times.

## What It Does

`setup.sh` runs these steps in order:

1. Xcode Command Line Tools
2. Homebrew
3. Brew packages & casks (`brew/.Brewfile`)
4. Prepare XDG / SSH / Claude directories
5. Stow all config packages as symlinks
6. Generate Ed25519 SSH key (no passphrase)
7. Proto + languages (Node.js, pnpm, Python)
8. VS Code extensions
9. Default shell → zsh
10. GPG agent with pinentry-mac
11. Fix file permissions (SSH, GnuPG, history)
12. macOS security hardening

## Packages

| Directory   | Target                                    | Description                          |
| ----------- | ----------------------------------------- | ------------------------------------ |
| `zsh/`      | `~/`                                      | Zsh config, aliases, functions       |
| `git/`      | `~/`                                      | Git config, delta pager, global ignore |
| `tmux/`     | `~/`                                      | Tmux with vi mode, true color        |
| `starship/` | `~/.config/`                              | Starship prompt (performance-tuned)  |
| `ghostty/`  | `~/.config/`                              | Ghostty terminal (catppuccin-mocha)  |
| `brew/`     | `~/`                                      | Homebrew Brewfile                    |
| `proto/`    | `~/`                                      | Proto language version manager       |
| `ssh/`      | `~/.ssh/` (no-folding)                    | SSH client hardening                 |
| `claude/`   | `~/.claude/` (no-folding)                 | Claude Code settings                 |
| `vscode/`   | `~/Library/Application Support/Code/User` | VS Code settings & extensions        |

Symlinks are managed by [GNU Stow](https://www.gnu.org/software/stow/). Most packages stow normally; `ssh` and `claude` use `--no-folding` to coexist with non-tracked files (keys, auto-generated configs).

## Tools

### Core

git, git-lfs, gnupg, jq, yq, stow, tmux, tree, gh, wget, xh

### Modern CLI Replacements

| Tool       | Replaces | Description                              |
| ---------- | -------- | ---------------------------------------- |
| `eza`      | `ls`     | Icons, git integration, tree view        |
| `bat`      | `cat`    | Syntax highlighting, git diffs           |
| `fd`       | `find`   | Simple, fast file finder                 |
| `ripgrep`  | `grep`   | Fast recursive search                    |
| `git-delta`| `diff`   | Side-by-side diffs with syntax highlight |
| `fzf`      | —        | Fuzzy finder (Ctrl-R, Ctrl-T, Alt-C)    |
| `zoxide`   | `cd`     | Smarter cd that learns directories       |
| `dust`     | `du`     | Visual disk usage tree                   |
| `duf`      | `df`     | Modern disk free                         |
| `btop`     | `htop`   | Resource monitor with GPU stats          |

### Dev

lazygit, lazydocker, direnv, colima, docker, docker-compose

### Security

age (encryption), gitleaks (secret scanning), pinentry-mac

## Shell

- **`.zshenv`** — PATH, XDG vars, Homebrew, Proto, Cargo, Go (`umask 077`)
- **`.zshrc`** — History (100k, dedup, secret filtering), completion (case-insensitive, menu, cache), plugins, aliases, fzf/zoxide/direnv integration, Starship prompt
- Plugin sources and tool integrations are guarded — shell works even before `brew bundle`

## Git

- GPG commit signing, delta pager (side-by-side), histogram diff algorithm
- `merge.conflictStyle = zdiff3`, `push.autoSetupRemote`, `pull.rebase`
- `rebase.updateRefs` for stacked branches, `fsmonitor` for fast status
- `fsckObjects` on transfer/fetch/receive for integrity
- Global gitignore blocks secrets (.env, keys, credentials)

## Security

- **SSH**: Ed25519 key auto-generated, `IdentitiesOnly`, `HashKnownHosts`, macOS Keychain integration
- **History**: `HIST_IGNORE_SPACE` + `zshaddhistory` hook blocks `API_KEY`, `TOKEN`, `PASSWORD` patterns
- **Permissions**: `umask 077`, scripts fix `~/.ssh` (700/600) and `~/.gnupg` (700/600)
- **macOS**: Firewall + stealth mode, Gatekeeper, screen lock on sleep, auto security updates, remote login disabled
- **Global gitignore**: `.env*`, `*.pem`, `*.key`, `id_*`, `credentials.json`, `.npmrc`, `.netrc`

## After Setup

1. Add SSH public key to GitHub: https://github.com/settings/keys
2. Import your GPG private key for git commit signing
3. Create `~/.gitconfig.local` for machine-specific settings (e.g. work email)
4. Enable FileVault if not already on (System Settings → Privacy & Security)

## Font

FiraMono Nerd Font — installed automatically via Homebrew.
