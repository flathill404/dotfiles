# dotfiles

Personal dotfiles for **macOS (Apple Silicon)** and **Linux/WSL**. One-command setup.

## Quick Start

```bash
git clone https://github.com/flathill404/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/setup.sh
```

The setup script is idempotent and auto-detects the OS — macOS-specific steps are skipped on Linux.

## What It Does

`setup.sh` runs these steps in order (macOS-only steps marked 🍎):

1. 🍎 Xcode Command Line Tools
2. 🍎 Homebrew
3. Packages: 🍎 Brew (`brew/.Brewfile`) / 🐧 apt (`scripts/install-linux-packages.sh`)
4. GitHub CLI auth (`gh auth login --web`, skipped if already authenticated)
5. Prepare XDG / SSH / Claude directories (un-folds any stray `~/.config` symlink into a real directory)
6. Stow all config packages as symlinks (all with `--no-folding` for safety)
7. Generate Ed25519 SSH key (no passphrase)
8. Register SSH key on GitHub (`gh ssh-key add`, skipped if already registered)
9. Proto + languages (Node.js, pnpm, Python)
10. 🍎 VS Code CLI setup
11. VS Code extensions
12. Default shell → zsh
13. GPG agent (pinentry-mac on macOS, pinentry-curses on Linux)
14. Fix file permissions (SSH, GnuPG, history)
15. 🍎 macOS security hardening
16. 🍎 macOS performance tuning
17. Re-stow config files (second pass to override any files created during install)

## Packages

| Directory   | Target                                    | Description                          |
| ----------- | ----------------------------------------- | ------------------------------------ |
| `zsh/`      | `~/`                                      | Zsh config, aliases, functions       |
| `git/`      | `~/`                                      | Git config, delta pager, global ignore |
| `tmux/`     | `~/`                                      | Tmux with vi mode, true color, OS-aware clipboard |
| `starship/` | `~/.config/`                              | Starship prompt (performance-tuned)  |
| `ghostty/`  | `~/.config/`                              | Ghostty terminal (catppuccin-mocha)  |
| `brew/`     | `~/`                                      | Homebrew Brewfile                    |
| `proto/`    | `~/`                                      | Proto language version manager       |
| `ssh/`      | `~/.ssh/`                                 | SSH client hardening                 |
| `claude/`   | `~/.claude/`                              | Claude Code settings                 |
| `karabiner/`| `~/.config/karabiner/`                    | Key remapping (right command ↔ fn)   |
| `vscode/`   | `~/Library/Application Support/Code/User` | VS Code settings & extensions (macOS)|

Symlinks are managed by [GNU Stow](https://www.gnu.org/software/stow/). **All packages stow with `--no-folding`** so only leaf files become symlinks — directory folding caused stow to repoint `~/.config` into this repo in the past, polluting it with every tool's auto-generated config.

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

On Debian/Ubuntu, `bat` and `fd` install as `batcat` and `fdfind` respectively — `.zshrc` aliases them to the canonical names.

### Dev
lazygit, lazydocker, direnv, colima, docker, docker-compose

### Security
age (encryption), gitleaks (secret scanning), pinentry-mac / pinentry-curses

## Shell

- **`.zshenv`** — PATH, XDG vars, Homebrew, Proto, Cargo, Go (`umask 077`)
- **`.zshrc`** — History (100k, dedup, broad secret-pattern filtering), completion (case-insensitive, menu, cache), plugins, aliases, fzf/zoxide/direnv integration, Starship prompt
- Plugin sources and tool integrations are guarded — shell works even before `brew bundle`/`apt install`

## Git

- GPG commit signing, delta pager (side-by-side), histogram diff algorithm
- `merge.conflictStyle = zdiff3`, `push.autoSetupRemote`, `pull.rebase`
- `rebase.updateRefs` for stacked branches, `fsmonitor` for fast status
- `fsckObjects` on transfer/fetch/receive for integrity
- Global gitignore blocks secrets (.env, keys, credentials)

The `[user]` block in the tracked `.gitconfig` does NOT include `signingkey` — it must live in `~/.gitconfig.local`:

```ini
[user]
    signingkey = <full-fingerprint>
```

## Security

- **SSH**: Ed25519 key auto-generated, `IdentitiesOnly`, `HashKnownHosts`, macOS Keychain integration; key registered on GitHub automatically via `gh ssh-key add`
- **GPG**: Private keys are NOT shipped in this repo. Use `scripts/gpg-export.sh` to back up to a private location (1Password / encrypted USB / private cloud) and `scripts/gpg-import.sh` to restore on a new machine
- **History**: `HIST_IGNORE_SPACE` + `zshaddhistory` hook blocks GitHub PATs (`ghp_*` etc.), OpenAI/Anthropic keys (`sk-*`), Slack tokens (`xox[abposr]-*`), AWS access keys, Google API keys, and generic `API_KEY` / `SECRET` / `TOKEN` / `PASSWORD` / `Bearer ` patterns (case-insensitive)
- **Permissions**: `umask 077`, scripts fix `~/.ssh` (700/600) and `~/.gnupg` (700/600)
- **macOS**: Firewall + stealth mode, Gatekeeper, screen lock on sleep, auto security updates, remote login disabled
- **Repo**: `.gitignore` fences off `*/config/*` directories so accidental tool writes can't be `git add`-ed; CI fails the build if any private-key-shaped file appears

## GPG Key Management

GPG private keys are managed **outside** this public repo.

**Backup** on the source machine:
```bash
./scripts/gpg-export.sh           # writes ./secret.gpg (passphrase-prompted)
# Store secret.gpg in a private location — 1Password / encrypted USB / private cloud
```

**Restore** on a new machine:
```bash
# Retrieve secret.gpg from your private storage, then:
./scripts/gpg-import.sh /path/to/secret.gpg

# Add the new fingerprint to ~/.gitconfig.local
gpg --list-secret-keys --keyid-format LONG
echo -e "[user]\n    signingkey = <fingerprint>" >> ~/.gitconfig.local

# Register the public key on GitHub
gpg --armor --export <fingerprint> | gh gpg-key add -
```

## After Setup

1. Create `~/.gitconfig.local` with your GPG `signingkey` (per machine)
2. Restore GPG private key if not generating fresh (see above)
3. Enable FileVault on macOS if not already on (System Settings → Privacy & Security)

## Font

FiraMono Nerd Font — installed automatically via Homebrew on macOS. Install manually on Linux.
