#!/usr/bin/env bash
# Fix permissions for sensitive directories.
# Safe to run multiple times.

set -euo pipefail

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }

# ── SSH ──────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.ssh" ]]; then
  info "Fixing ~/.ssh permissions..."
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
  find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \;
  [[ -f "$HOME/.ssh/config" ]] && chmod 644 "$HOME/.ssh/config"
  [[ -f "$HOME/.ssh/known_hosts" ]] && chmod 644 "$HOME/.ssh/known_hosts"
  success "SSH permissions fixed"
fi

# ── GnuPG ────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.gnupg" ]]; then
  info "Fixing ~/.gnupg permissions..."
  chmod 700 "$HOME/.gnupg"
  find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
  find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
  success "GnuPG permissions fixed"
fi

# ── Zsh History ──────────────────────────────────────────────────────────────
HIST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
if [[ -f "$HIST_DIR/history" ]]; then
  info "Fixing zsh history permissions..."
  chmod 600 "$HIST_DIR/history"
  success "Zsh history permissions fixed"
fi

echo ""
success "Permissions fixed."
