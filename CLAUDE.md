# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS Apple Silicon. Symlinks are managed by GNU Stow — each top-level directory (e.g. `zsh/`, `git/`) mirrors the target filesystem layout so `stow <dir>` creates the correct symlinks.

## Setup

```bash
./scripts/setup.sh    # idempotent one-command bootstrap
```

The setup script runs: Xcode CLI tools → Homebrew → Brew Bundle → Stow configs → Proto languages → VSCode extensions → default shell → GPG agent.

## Stow Conventions

Each package directory's internal structure maps to its stow target (default `$HOME`). For example, `zsh/.zshrc` stows to `~/.zshrc`. VSCode is the exception — it targets `~/Library/Application Support/Code/User`.

Stowed packages: `zsh`, `git`, `tmux`, `starship`, `ghostty`, `brew`, `proto`, `claude`.

To re-stow after changes:
```bash
stow --restow <package>                    # most packages
stow --restow --no-folding claude          # file-level symlinks (coexists with auto-generated files)
stow --restow --target="$HOME/Library/Application Support/Code/User" vscode
```

## Key Details

- `.gitignore` excludes `.env`, `*.local`, `*.local.*` — machine-specific overrides (like `~/.gitconfig.local`) stay out of version control
- Git config includes `~/.gitconfig.local` for per-machine settings (work email, etc.)
- Proto manages Node.js, pnpm, and Python versions (see `proto/.prototools`)
- Brew packages are declared in `brew/.Brewfile` — use `brew bundle --file=brew/.Brewfile` to sync
- Shell environment setup is split: `.zshenv` (PATH, env vars loaded by all shells) vs `.zshrc` (interactive config, aliases, plugins)
