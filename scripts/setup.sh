#!/usr/bin/env bash
# One-command setup for macOS (Apple Silicon) and Linux/WSL.
# Safe to run multiple times — each step is idempotent.
#
# Failure policy: `set -e` is intentionally NOT used. Individual steps may
# fail (e.g. macOS-only commands on Linux, missing optional tools) — we log
# the failure via `run_step` and continue. Use `set -e` inside individual
# helpers if you need fail-fast semantics within that helper.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/brew/.Brewfile"
EXTENSIONS_FILE="$DOTFILES_DIR/vscode/extensions.json"

# ── OS detection ─────────────────────────────────────────────────────────────

OS="unknown"
case "$(uname)" in
  Darwin) OS="macos" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS="wsl"
    else
      OS="linux"
    fi
    ;;
esac

is_macos() { [[ "$OS" == "macos" ]]; }
is_linux() { [[ "$OS" == "linux" || "$OS" == "wsl" ]]; }

# ── Logging helpers ──────────────────────────────────────────────────────────

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m  %s\n' "$1"; }
fail()    { printf '\033[31m[FAIL]\033[0m  %s\n' "$1"; }
skip()    { printf '\033[37m[SKIP]\033[0m  %s\n' "$1"; }

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
  case "$OS" in
    macos)
      if [[ "$(uname -m)" != "arm64" ]]; then
        fail "macOS Intel is not supported (Apple Silicon only)."; exit 1
      fi
      success "macOS Apple Silicon detected"
      ;;
    linux|wsl)
      success "Linux ($OS) detected — macOS-specific steps will be skipped"
      ;;
    *)
      fail "Unsupported OS: $(uname)"; exit 1
      ;;
  esac
}

# ── Step 1: Xcode Command Line Tools (macOS only) ───────────────────────────

install_xcode_cli() {
  if ! is_macos; then skip "Xcode CLI (macOS only)"; return 0; fi
  if xcode-select -p &>/dev/null; then
    success "Xcode CLI tools already installed"
    return 0
  fi
  info "Installing Xcode CLI tools (a dialog may appear)..."
  xcode-select --install
  # Wait up to 30 minutes for installation; fail loudly if it stalls.
  local waited=0
  while ! xcode-select -p &>/dev/null; do
    sleep 5
    waited=$((waited + 5))
    if (( waited > 1800 )); then
      fail "Xcode CLI install timed out after 30 minutes"
      return 1
    fi
  done
}

# ── Step 2: Package manager (Homebrew on macOS, apt on Linux) ───────────────

install_homebrew() {
  if ! is_macos; then skip "Homebrew (macOS only)"; return 0; fi
  if command -v brew &>/dev/null; then
    success "Homebrew already installed"
    return 0
  fi
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_brew_packages() {
  if ! is_macos; then skip "Brew bundle (macOS only)"; return 0; fi
  brew bundle --file="$BREWFILE"
}

# Linux package install is delegated to a dedicated script, mirroring how
# brew/.Brewfile is a separate declarative inventory on macOS.
install_linux_packages() {
  if ! is_linux; then skip "apt packages (Linux only)"; return 0; fi
  "$DOTFILES_DIR/scripts/install-linux-packages.sh"
}

# ── Step 3: GitHub CLI Auth ─────────────────────────────────────────────────

setup_gh_auth() {
  if ! command -v gh &>/dev/null; then
    warn "gh not installed — skipping auth"
    return 0
  fi
  if gh auth status &>/dev/null; then
    success "GitHub CLI already authenticated"
    return 0
  fi
  info "Authenticating with GitHub CLI (browser will open)..."
  gh auth login --web --git-protocol https
}

# ── Step 4: Prepare directories ─────────────────────────────────────────────

# Convert a stray symlink at $1 (pointing into our dotfiles repo) back
# into a real directory. This recovers from past stow-folding incidents
# where, e.g., ~/.config got folded into dotfiles/git/.config.
unfold_symlink_dir() {
  local path="$1"
  [[ ! -L "$path" ]] && return 0
  local target
  target="$(readlink -f "$path" 2>/dev/null || true)"
  if [[ -z "$target" || "$target" != "$DOTFILES_DIR"* ]]; then
    return 0  # symlink doesn't point into our repo — leave it alone
  fi
  warn "Detected folded symlink: $path → $target (un-folding to a real directory)"
  local tmp
  tmp="$(mktemp -d "${path}.unfold.XXXXXX")"
  # Copy the resolved contents (skip pseudo-entries)
  if [[ -d "$target" ]]; then
    (cd "$target" && find . -mindepth 1 -maxdepth 1 -print0 \
      | xargs -0 -I{} cp -a {} "$tmp/")
  fi
  rm "$path"
  mv "$tmp" "$path"
  success "Un-folded: $path is now a real directory"
}

prepare_directories() {
  # XDG directories
  mkdir -p "$HOME/.local/share"
  mkdir -p "$HOME/.local/state/zsh"
  mkdir -p "$HOME/.cache/zsh"
  mkdir -p "$HOME/.local/bin"

  # ~/.config must be a REAL directory before any stow runs, otherwise
  # stow may fold the entire ~/.config tree into our repo.
  unfold_symlink_dir "$HOME/.config"
  mkdir -p "$HOME/.config"

  # Pre-create per-tool .config subdirectories so stow links files, not folders
  mkdir -p "$HOME/.config/git"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$HOME/.config/karabiner"
  mkdir -p "$HOME/.config/starship"  # not strictly needed but consistent

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
      local real_dest
      real_dest=$(realpath "$dest" 2>/dev/null || echo "")
      if [[ -n "$real_dest" && "$real_dest" == "$DOTFILES_DIR"* ]]; then
        continue  # already owned by our dotfiles
      fi
      warn "Backing up conflicting file: $dest → ${dest}.dotfiles.bak"
      mv "$dest" "${dest}.dotfiles.bak"
    fi
  done
}

# Wrapper around `stow --restow` that always uses --no-folding for packages
# that target a shared directory (~/.config, ~/.ssh, ~/.claude). This
# guarantees stow creates leaf-file symlinks, never folder symlinks — so
# tools cannot accidentally write into our repo via a folded ancestor.
stow_pkg() {
  local pkg="$1"
  local target="${2:-$HOME}"
  local extra_opts="${3:-}"
  [[ ! -d "$DOTFILES_DIR/$pkg" ]] && return 0
  info "Stowing $pkg..."
  backup_stow_conflicts "$pkg" "$target"
  # shellcheck disable=SC2086 # extra_opts is intentionally word-split
  if ! stow --restow --no-folding $extra_opts --target="$target" "$pkg"; then
    warn "Failed to stow $pkg"
  fi
}

stow_configs() {
  cd "$DOTFILES_DIR" || return 1

  # All home-targeting packages stow with --no-folding for safety.
  for pkg in zsh git tmux starship ghostty brew proto ssh claude karabiner; do
    stow_pkg "$pkg"
  done

  # VSCode targets ~/Library/Application Support/Code/User (macOS only)
  if is_macos; then
    local vscode_target="$HOME/Library/Application Support/Code/User"
    mkdir -p "$vscode_target"
    stow_pkg vscode "$vscode_target"
  else
    skip "vscode stow (macOS Library path)"
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
}

# ── Step 6b: Register SSH Key on GitHub ─────────────────────────────────────

register_ssh_key() {
  local pub_key="$HOME/.ssh/id_ed25519.pub"

  if [[ ! -f "$pub_key" ]]; then
    warn "No SSH public key found — skipping GitHub registration"
    return 0
  fi

  if ! command -v gh &>/dev/null || ! gh auth status &>/dev/null; then
    warn "gh not available/authenticated — skipping SSH key registration"
    return 0
  fi

  local fingerprint
  fingerprint="$(ssh-keygen -lf "$pub_key" | awk '{print $2}')"

  if gh ssh-key list 2>/dev/null | grep -qF "$fingerprint"; then
    success "SSH key already registered on GitHub"
    return 0
  fi

  gh ssh-key add "$pub_key" --title "$(hostname -s)" --type authentication
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

# ── Step 7.5: VS Code CLI (macOS only) ──────────────────────────────────────

setup_vscode_cli() {
  if ! is_macos; then skip "VS Code CLI symlink (macOS only)"; return 0; fi
  if command -v code &>/dev/null; then
    success "VS Code 'code' command already available"
    return 0
  fi

  local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ ! -f "$code_bin" ]]; then
    warn "VS Code app not found — skipping 'code' CLI setup"
    return 0
  fi

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
  local zsh_path
  zsh_path="$(command -v zsh || echo "")"
  if [[ -z "$zsh_path" ]]; then
    warn "zsh not installed — skipping shell change"
    return 0
  fi
  if [[ "$SHELL" == "$zsh_path" || "${SHELL##*/}" == "zsh" ]]; then
    success "Default shell is already zsh"
    return 0
  fi
  if ! chsh -s "$zsh_path" 2>/dev/null; then
    warn "Could not change default shell to zsh (password required or non-interactive)"
    warn "Run manually: chsh -s $zsh_path"
    return 0
  fi
  success "Default shell changed to zsh"
}

# ── Step 10: GPG Agent (pinentry) ───────────────────────────────────────────
#
# GPG private key management is intentionally manual:
#   1. Generate a key on this machine, OR import one securely
#      (1Password / Keychain / scp from a trusted host).
#   2. Add `signingkey = <full-fingerprint>` to ~/.gitconfig.local.
#   3. Register the public key on GitHub via `gh gpg-key add`.
#
# We DO NOT store private keys (encrypted or otherwise) in this public repo.

configure_gpg() {
  local gpg_dir="$HOME/.gnupg"
  mkdir -p "$gpg_dir"
  chmod 700 "$gpg_dir"

  local agent_conf="$gpg_dir/gpg-agent.conf"
  local pinentry_path=""

  if is_macos && [[ -f "/opt/homebrew/bin/pinentry-mac" ]]; then
    pinentry_path="/opt/homebrew/bin/pinentry-mac"
  elif is_linux && command -v pinentry-curses &>/dev/null; then
    pinentry_path="$(command -v pinentry-curses)"
  fi

  if [[ -n "$pinentry_path" ]]; then
    if ! grep -q "pinentry-program" "$agent_conf" 2>/dev/null; then
      echo "pinentry-program $pinentry_path" >> "$agent_conf"
      success "Configured pinentry: $pinentry_path"
    else
      success "GPG pinentry already configured"
    fi
  else
    warn "No pinentry binary found — install pinentry-mac (macOS) or pinentry-curses (Linux)"
  fi
}

# ── Git credential helper (per-OS) ──────────────────────────────────────────
#
# osxkeychain is macOS-only; on Linux/WSL it errors on every credential
# lookup. The helper is OS-specific, so it lives in ~/.gitconfig.local
# (machine-local, like the GPG signingkey) rather than the tracked .gitconfig.

configure_git_credential() {
  local local_cfg="$HOME/.gitconfig.local"
  touch "$local_cfg"

  if [[ -n "$(git config --file "$local_cfg" --get credential.helper 2>/dev/null)" ]]; then
    success "git credential helper already configured (~/.gitconfig.local)"
    return 0
  fi

  local helper=""
  if is_macos; then
    helper="osxkeychain"
  elif is_linux; then
    helper="cache --timeout=86400"
  fi

  if [[ -n "$helper" ]]; then
    git config --file "$local_cfg" credential.helper "$helper"
    success "Configured git credential helper: $helper"
  else
    warn "Unknown OS — set credential.helper manually in ~/.gitconfig.local"
  fi
}

# ── Step 11: Fix Permissions ────────────────────────────────────────────────

fix_permissions() {
  "$DOTFILES_DIR/scripts/fix-permissions.sh"
}

# ── Step 12: macOS Hardening (macOS only) ───────────────────────────────────

macos_hardening() {
  if ! is_macos; then skip "macOS hardening (macOS only)"; return 0; fi
  "$DOTFILES_DIR/scripts/macos-hardening.sh"
}

# ── Step 13: macOS Speedup (macOS only) ─────────────────────────────────────

macos_speedup() {
  if ! is_macos; then skip "macOS speedup (macOS only)"; return 0; fi
  "$DOTFILES_DIR/scripts/macos-speedup.sh"
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
  run_step "apt packages (Linux)"        install_linux_packages
  run_step "GitHub CLI auth"             setup_gh_auth
  run_step "Prepare directories"         prepare_directories
  run_step "Stow config files"           stow_configs
  run_step "SSH key generation"          generate_ssh_key
  run_step "Register SSH key on GitHub"  register_ssh_key
  run_step "Proto + languages"           setup_proto
  run_step "VS Code CLI setup"           setup_vscode_cli
  run_step "VSCode extensions"           install_vscode_extensions
  run_step "Default shell (zsh)"         set_default_shell
  run_step "GPG agent configuration"     configure_gpg
  run_step "Git credential helper"       configure_git_credential
  run_step "Fix file permissions"        fix_permissions
  run_step "macOS security hardening"    macos_hardening
  run_step "macOS performance tuning"    macos_speedup
  # Second pass: catches files that step 3 (package install) may have created
  # at stow target paths (e.g. ~/.config/git/ignore via apt git package).
  run_step "Re-stow config files"        stow_configs

  echo ""
  success "Setup complete! Open a new terminal to apply all changes."
  echo ""
  info "Manual steps remaining:"
  info "  1. Create ~/.gitconfig.local with your GPG signingkey:"
  info "       [user] signingkey = <full-fingerprint>"
  info "  2. Generate or import a GPG key (this repo does NOT ship one):"
  info "       gpg --full-generate-key  # then: gh gpg-key add"
  if is_macos; then
    info "  3. Enable FileVault in System Settings if not already on"
  fi
  echo ""
}

main "$@"
