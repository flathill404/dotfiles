# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS Apple Silicon and Linux/WSL. Symlinks are managed by GNU Stow — each top-level directory (e.g. `zsh/`, `git/`) mirrors the target filesystem layout so `stow <dir>` creates the correct symlinks.

## Setup

```bash
./scripts/setup.sh    # idempotent one-command bootstrap (macOS or Linux/WSL)
```

The setup script auto-detects the OS and runs only the applicable steps.

Step order (macOS-only steps are skipped on Linux):

1. Xcode Command Line Tools (macOS)
2. Homebrew (macOS)
3. Brew packages & casks (macOS) / apt packages (Linux)
4. GitHub CLI auth (`gh auth login --web` — skipped if already authenticated)
5. Prepare directories — including un-folding any stray `~/.config` symlink back into a real directory
6. Stow config files (all packages use `--no-folding` for safety)
7. SSH key generation
8. Register SSH key on GitHub (`gh ssh-key add` — duplicate-checked by fingerprint)
9. Proto + languages (Node.js, pnpm, Python)
10. VS Code CLI setup (macOS)
11. VS Code extensions
12. Default shell (zsh)
13. GPG agent configuration (pinentry-mac on macOS, pinentry-curses on Linux)
14. Fix file permissions
15. macOS security hardening (macOS)
16. macOS performance tuning (macOS)
17. Re-stow config files (second pass to replace any files created during install)

GPG private keys are NOT shipped in this repo. Import manually via `scripts/gpg-import.sh /path/to/secret.gpg` after retrieving the encrypted key from your private storage.

## Stow Conventions

Each package directory's internal structure maps to its stow target (default `$HOME`). For example, `zsh/.zshrc` stows to `~/.zshrc`. VSCode is the exception — it targets `~/Library/Application Support/Code/User`.

Stowed packages: `zsh`, `git`, `tmux`, `starship`, `ghostty`, `brew`, `proto`, `ssh`, `claude`, `karabiner`.

**All packages stow with `--no-folding`** to prevent stow from creating directory-level symlinks. Directory-level folding caused real bugs in the past — for example, `~/.config` getting folded into `dotfiles/git/.config`, so every tool that wrote to `~/.config/<x>` polluted this repo. With `--no-folding`, only individual leaf files become symlinks.

To re-stow after changes:
```bash
stow --restow --no-folding <package>                         # standard packages
stow --restow --no-folding --target="$HOME/Library/Application Support/Code/User" vscode
```

## Key Details

- `.gitignore` includes a defensive fence around `git/.config/*`, `starship/.config/*`, `ghostty/.config/*`, `karabiner/.config/*` — only tracked tool subdirs are allowed; anything else accidentally written into the repo is ignored
- `.gitignore` excludes `.env`, `.env.*`, `.envrc`, `*.local`, `*.local.*`, `*.pem`, `*.key`, `secret.gpg`, `private-key*`
- Global gitignore at `git/.config/git/ignore` blocks secrets (keys, credentials, .env files) from any repo
- Git config includes `~/.gitconfig.local` for per-machine settings — the GPG `signingkey` MUST live there, never in the tracked `.gitconfig`
- Proto manages Node.js, pnpm, and Python versions (see `proto/.prototools`)
- Brew packages are declared in `brew/.Brewfile` — use `brew bundle --file=brew/.Brewfile` to sync (macOS only)
- Shell environment setup is split: `.zshenv` (PATH, env vars loaded by all shells) vs `.zshrc` (interactive config, aliases, plugins)
- GPG key handling: backup with `scripts/gpg-export.sh /path/to/secret.gpg` (writes outside this repo), restore with `scripts/gpg-import.sh /path/to/secret.gpg`. The encrypted file must be stored in a private location (1Password / encrypted USB / private cloud), never in this public repo
