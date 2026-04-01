#!/usr/bin/env bash
# One-command setup for macOS (Apple Silicon).
# Safe to run multiple times — each step is idempotent.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/brew/.Brewfile"
EXTENSIONS_FILE="$DOTFILES_DIR/vscode/extensions.json"

# ── Logging helpers ──────────────────────────────────────────────────────────

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m  %s\n' "$1"; }
fail()    { printf '\033[31m[FAIL]\033[0m  %s\n' "$1"; }

run_step() {
  local description="$1"; shift
  info "$description"
  if "$@"; then
    success "$description"
  else
    fail "$description — skipping and continuing"
  fi
}

# ── Pre-flight ───────────────────────────────────────────────────────────────

preflight() {
  if [[ "$(uname)" != "Darwin" ]]; then
    fail "This script only supports macOS."; exit 1
  fi
  if [[ "$(uname -m)" != "arm64" ]]; then
    fail "This script only supports Apple Silicon Macs."; exit 1
  fi
  success "Apple Silicon Mac detected"
}

# ── Step 1: Xcode Command Line Tools ────────────────────────────────────────

install_xcode_cli() {
  if xcode-select -p &>/dev/null; then
    success "Xcode CLI tools already installed"
    return 0
  fi
  info "Installing Xcode CLI tools (a dialog may appear)..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
}

# ── Step 2: Homebrew ────────────────────────────────────────────────────────

install_homebrew() {
  if command -v brew &>/dev/null; then
    success "Homebrew already installed"
    return 0
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# ── Step 3: Brew Bundle ─────────────────────────────────────────────────────

install_brew_packages() {
  brew bundle --file="$BREWFILE" --no-lock
}

# ── Step 4: Prepare directories ─────────────────────────────────────────────

prepare_directories() {
  # XDG directories
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"
  mkdir -p "$HOME/.local/state/zsh"
  mkdir -p "$HOME/.cache/zsh"
  mkdir -p "$HOME/.local/bin"

  # SSH directory (must exist before stow)
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
}

# ── Step 5: Stow Configs ────────────────────────────────────────────────────

stow_configs() {
  local packages=(zsh git tmux starship ghostty brew proto)
  cd "$DOTFILES_DIR" || return 1

  for pkg in "${packages[@]}"; do
    if [[ -d "$pkg" ]]; then
      info "Stowing $pkg..."
      stow --restow "$pkg" 2>/dev/null || warn "Failed to stow $pkg (check for conflicting files)"
    fi
  done

  # SSH needs --no-folding to coexist with keys and known_hosts
  info "Stowing ssh..."
  stow --restow --no-folding ssh 2>/dev/null \
    || warn "Failed to stow ssh (check for conflicting files)"

  # Claude needs --no-folding to coexist with auto-generated files in ~/.claude/
  info "Stowing claude..."
  stow --restow --no-folding claude 2>/dev/null \
    || warn "Failed to stow claude (check for conflicting files)"

  # VSCode requires a custom target directory
  local vscode_target="$HOME/Library/Application Support/Code/User"
  mkdir -p "$vscode_target"
  info "Stowing vscode..."
  stow --restow --target="$vscode_target" vscode 2>/dev/null \
    || warn "Failed to stow vscode (check for conflicting files)"
}

# ── Step 6: Proto + Languages ───────────────────────────────────────────────

setup_proto() {
  if ! command -v proto &>/dev/null; then
    info "Installing proto..."
    curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes
    export PROTO_HOME="$HOME/.proto"
    export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
  fi

  if ! command -v proto &>/dev/null; then
    fail "Proto installation failed"
    return 1
  fi

  proto install node latest
  proto install pnpm latest
  proto install python latest
}

# ── Step 7: VSCode Extensions ───────────────────────────────────────────────

install_vscode_extensions() {
  if ! command -v code &>/dev/null; then
    warn "VS Code 'code' command not found — skipping extensions"
    warn "Open VS Code and run 'Shell Command: Install code command in PATH' first"
    return 0
  fi

  if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    warn "extensions.json not found — skipping"
    return 0
  fi

  jq -r '.recommendations[]' "$EXTENSIONS_FILE" | while read -r ext; do
    code --install-extension "$ext" --force 2>/dev/null \
      || warn "Failed to install extension: $ext"
  done
}

# ── Step 8: fzf key bindings ────────────────────────────────────────────────

setup_fzf() {
  if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    success "fzf key bindings installed"
  fi
}

# ── Step 9: Default Shell ───────────────────────────────────────────────────

set_default_shell() {
  if [[ "$SHELL" == "/bin/zsh" ]]; then
    success "Default shell is already zsh"
    return 0
  fi
  chsh -s /bin/zsh
}

# ── Step 10: GPG Agent (pinentry-mac) ───────────────────────────────────────

configure_gpg() {
  local gpg_dir="$HOME/.gnupg"
  mkdir -p "$gpg_dir"
  chmod 700 "$gpg_dir"

  local agent_conf="$gpg_dir/gpg-agent.conf"
  local pinentry_path
  pinentry_path="$(brew --prefix)/bin/pinentry-mac"

  if [[ -f "$pinentry_path" ]]; then
    if ! grep -q "pinentry-program" "$agent_conf" 2>/dev/null; then
      echo "pinentry-program $pinentry_path" >> "$agent_conf"
      success "Configured pinentry-mac for GPG"
    else
      success "GPG pinentry already configured"
    fi
  fi
}

# ── Step 11: Fix Permissions ────────────────────────────────────────────────

fix_permissions() {
  "$DOTFILES_DIR/scripts/fix-permissions.sh"
}

# ── Step 12: macOS Hardening ────────────────────────────────────────────────

macos_hardening() {
  "$DOTFILES_DIR/scripts/macos-hardening.sh"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  ┌─────────────────────────────────────┐"
  echo "  │  flathill404/dotfiles setup          │"
  echo "  └─────────────────────────────────────┘"
  echo ""

  preflight

  run_step "Xcode Command Line Tools"   install_xcode_cli
  run_step "Homebrew"                    install_homebrew
  run_step "Brew packages & casks"       install_brew_packages
  run_step "Prepare directories"         prepare_directories
  run_step "Stow config files"           stow_configs
  run_step "Proto + languages"           setup_proto
  run_step "VSCode extensions"           install_vscode_extensions
  run_step "fzf key bindings"            setup_fzf
  run_step "Default shell (zsh)"         set_default_shell
  run_step "GPG agent configuration"     configure_gpg
  run_step "Fix file permissions"        fix_permissions
  run_step "macOS security hardening"    macos_hardening

  echo ""
  success "Setup complete! Open a new terminal to apply all changes."
  echo ""
  info "Manual steps remaining:"
  info "  1. Import your GPG private key for git commit signing"
  info "  2. Create ~/.gitconfig.local for machine-specific git settings"
  info "  3. Generate SSH key: ssh-keygen -t ed25519 -a 100"
  info "  4. Enable FileVault in System Settings if not already on"
  echo ""
}

main "$@"
