# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS Apple Silicon. Symlinks are managed by GNU Stow — each top-level directory (e.g. `zsh/`, `git/`) mirrors the target filesystem layout so `stow <dir>` creates the correct symlinks.

## Setup

```bash
./scripts/setup.sh    # idempotent one-command bootstrap
```

The setup script runs in this order:

1. Xcode Command Line Tools
2. Homebrew
3. Brew packages & casks
4. GitHub CLI auth (`gh auth login --web` — skipped if already authenticated)
5. Prepare directories
6. Stow config files
7. SSH key generation
8. Register SSH key on GitHub (`gh ssh-key add` — duplicate-checked by fingerprint)
9. Proto + languages (Node.js, pnpm, Python)
10. VS Code CLI setup
11. VSCode extensions
12. Default shell (zsh)
13. GPG key import (decrypts `gnupg/private-key.gpg.asc` and imports — skipped if key already in keyring)
14. GPG agent configuration (pinentry-mac)
15. Register GPG key on GitHub (`gh gpg-key add` — duplicate-checked by key ID)
16. Fix file permissions
17. macOS security hardening
18. Re-stow config files (second pass to replace any files created during setup)

## Stow Conventions

Each package directory's internal structure maps to its stow target (default `$HOME`). For example, `zsh/.zshrc` stows to `~/.zshrc`. VSCode is the exception — it targets `~/Library/Application Support/Code/User`.

Stowed packages: `zsh`, `git`, `tmux`, `starship`, `ghostty`, `brew`, `proto`, `ssh`, `claude`, `karabiner`.

To re-stow after changes:
```bash
stow --restow <package>                    # most packages
stow --restow --no-folding ssh             # file-level symlinks (coexists with keys)
stow --restow --no-folding claude          # file-level symlinks (coexists with auto-generated files)
stow --restow --target="$HOME/Library/Application Support/Code/User" vscode
```

## Key Details

- `.gitignore` excludes `.env`, `.env.*`, `.envrc`, `*.local`, `*.local.*` — machine-specific overrides (like `~/.gitconfig.local`) stay out of version control
- Global gitignore at `git/.config/git/ignore` blocks secrets (keys, credentials, .env files) from any repo
- Git config includes `~/.gitconfig.local` for per-machine settings (work email, etc.)
- Proto manages Node.js, pnpm, and Python versions (see `proto/.prototools`)
- Brew packages are declared in `brew/.Brewfile` — use `brew bundle --file=brew/.Brewfile` to sync
- Shell environment setup is split: `.zshenv` (PATH, env vars loaded by all shells) vs `.zshrc` (interactive config, aliases, plugins)
- GPG private key is stored encrypted at `gnupg/private-key.gpg.asc` (AES256 symmetric encryption); setup decrypts and imports it automatically. To re-export from an existing machine, run `scripts/gpg-export.sh`
