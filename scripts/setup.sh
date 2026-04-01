#!/usr/bin/env bash
# One-command setup for macOS (Apple Silicon).
# Safe to run multiple times — each step is idempotent.

set -uo pipefail

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
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# ── Step 3: Brew Bundle ─────────────────────────────────────────────────────

install_brew_packages() {
  brew bundle --file="$BREWFILE"
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

  # Claude directory (must exist before stow --no-folding)
  mkdir -p "$HOME/.claude"
}

# ── Step 5: Stow Configs ────────────────────────────────────────────────────

# Back up any non-symlink files that would conflict with stow.
# This lets setup.sh run safely on machines that already have dotfiles.
# Backed-up files get a .dotfiles.bak suffix; nothing is silently deleted.
#
# Safety: if $dest resolves (via symlinks) to a path inside $DOTFILES_DIR,
# it is already managed by stow — skip it to avoid renaming our own files.
backup_stow_conflicts() {
  local pkg="$1"
  local target="${2:-$HOME}"
  local pkg_dir="$DOTFILES_DIR/$pkg"

  find "$pkg_dir" -type f | while IFS= read -r src; do
    local rel="${src#${pkg_dir}/}"
    local dest="$target/$rel"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      # Check if the real path of $dest lives inside our dotfiles directory.
      # This happens when an ancestor directory is already a stow symlink
      # pointing back into DOTFILES_DIR (e.g. ~/.config/git → dotfiles/git/.config/git).
      local real_dest
      real_dest=$(realpath "$dest" 2>/dev/null || echo "")
      if [[ -n "$real_dest" && "$real_dest" == "$DOTFILES_DIR"* ]]; then
        # Already owned by our dotfiles — do not touch it.
        continue
      fi
      warn "Backing up conflicting file: $dest → ${dest}.dotfiles.bak"
      mv "$dest" "${dest}.dotfiles.bak"
    fi
  done
}

stow_configs() {
  local packages=(zsh git tmux starship ghostty brew proto)
  cd "$DOTFILES_DIR" || return 1

  for pkg in "${packages[@]}"; do
    if [[ -d "$pkg" ]]; then
      info "Stowing $pkg..."
      backup_stow_conflicts "$pkg"
      if ! stow --restow --target="$HOME" "$pkg"; then
        warn "Failed to stow $pkg — check for conflicting files above"
      fi
    fi
  done

  # SSH needs --no-folding to coexist with keys and known_hosts
  info "Stowing ssh..."
  backup_stow_conflicts "ssh"
  if ! stow --restow --no-folding --target="$HOME" ssh; then
    warn "Failed to stow ssh"
  fi

  # Claude needs --no-folding to coexist with auto-generated files in ~/.claude/
  info "Stowing claude..."
  backup_stow_conflicts "claude"
  if ! stow --restow --no-folding --target="$HOME" claude; then
    warn "Failed to stow claude"
  fi

  # VSCode requires a custom target directory
  local vscode_target="$HOME/Library/Application Support/Code/User"
  mkdir -p "$vscode_target"
  info "Stowing vscode..."
  backup_stow_conflicts "vscode" "$vscode_target"
  if ! stow --restow --target="$vscode_target" vscode; then
    warn "Failed to stow vscode"
  fi
}

# ── Step 6: SSH Key Generation ──────────────────────────────────────────────

generate_ssh_key() {
  local key_path="$HOME/.ssh/id_ed25519"

  if [[ -f "$key_path" ]]; then
    success "SSH key already exists at $key_path"
    return 0
  fi

  info "Generating Ed25519 SSH key (no passphrase)..."
  ssh-keygen -t ed25519 -a 100 -f "$key_path" -N "" -C "flathill404"
  chmod 600 "$key_path"
  chmod 644 "${key_path}.pub"
  success "SSH key generated"

  echo ""
  info "Public key (add to GitHub → Settings → SSH keys):"
  echo ""
  cat "${key_path}.pub"
  echo ""
}

# ── Step 7: Proto + Languages ───────────────────────────────────────────────

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

# ── Step 7.5: VS Code CLI ───────────────────────────────────────────────────

# brew install --cask visual-studio-code places the app bundle in /Applications
# but does NOT automatically create the `code` shell command.
# This mirrors what VS Code's built-in "Install 'code' command in PATH" does.
setup_vscode_cli() {
  if command -v code &>/dev/null; then
    success "VS Code 'code' command already available"
    return 0
  fi

  local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ ! -f "$code_bin" ]]; then
    warn "VS Code app not found — skipping 'code' CLI setup"
    return 0
  fi

  # Prefer /usr/local/bin (always in system PATH); fall back to ~/.local/bin
  if [[ -w /usr/local/bin ]]; then
    ln -sf "$code_bin" /usr/local/bin/code
    success "'code' command installed at /usr/local/bin/code"
  else
    ln -sf "$code_bin" "$HOME/.local/bin/code"
    success "'code' command installed at $HOME/.local/bin/code"
  fi
}

# ── Step 8: VSCode Extensions ───────────────────────────────────────────────

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

# ── Step 9: Default Shell ───────────────────────────────────────────────────

set_default_shell() {
  if [[ "$SHELL" == "/bin/zsh" ]]; then
    success "Default shell is already zsh"
    return 0
  fi
  # chsh requires interactive password auth; skip silently in non-interactive
  # environments (CI runners, sudo-less sessions).
  if ! chsh -s /bin/zsh 2>/dev/null; then
    warn "Could not change default shell to zsh (password required or non-interactive)"
    warn "Run manually: chsh -s /bin/zsh"
    return 0
  fi
  success "Default shell changed to zsh"
}

# ── Step 10: GPG Agent (pinentry-mac) ───────────────────────────────────────

configure_gpg() {
  local gpg_dir="$HOME/.gnupg"
  mkdir -p "$gpg_dir"
  chmod 700 "$gpg_dir"

  local agent_conf="$gpg_dir/gpg-agent.conf"
  local pinentry_path="/opt/homebrew/bin/pinentry-mac"

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
  run_step "SSH key generation"          generate_ssh_key
  run_step "Proto + languages"           setup_proto
  run_step "VS Code CLI setup"           setup_vscode_cli
  run_step "VSCode extensions"           install_vscode_extensions
  run_step "Default shell (zsh)"         set_default_shell
  run_step "GPG agent configuration"     configure_gpg
  run_step "Fix file permissions"        fix_permissions
  run_step "macOS security hardening"    macos_hardening
  # Re-stow after all installs: brew/git/gh may have created real files at the
  # symlink targets (e.g. ~/.config/git/ignore, VS Code extensions.json).
  # A second pass backs those up and replaces them with our dotfiles symlinks.
  run_step "Re-stow config files"        stow_configs

  echo ""
  success "Setup complete! Open a new terminal to apply all changes."
  echo ""
  info "Manual steps remaining:"
  info "  1. Add SSH public key to GitHub: https://github.com/settings/keys"
  info "  2. Import your GPG private key for git commit signing"
  info "  3. Create ~/.gitconfig.local for machine-specific git settings"
  info "  4. Enable FileVault in System Settings if not already on"
  echo ""
}

main "$@"
