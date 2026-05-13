#!/usr/bin/env bash
# Install Linux equivalents of the CLI tools declared in brew/.Brewfile.
# Debian/Ubuntu (apt) only. For other distros, install equivalents manually.
#
# Cask-only Brewfile entries (Ghostty, VS Code, Chrome, Karabiner-Elements,
# Slack, Rectangle, fonts) are intentionally NOT handled here — install
# those via your distro's package manager or vendor instructions.

set -uo pipefail

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m  %s\n' "$1"; }

if ! command -v apt-get &>/dev/null; then
  warn "Non-Debian Linux detected — install brew/.Brewfile equivalents manually"
  exit 0
fi

# ── apt packages (CLI tools available from Ubuntu/Debian main repos) ────────

APT_PACKAGES=(
  # Core
  git git-lfs gnupg jq stow tmux tree wget curl
  # Shell
  zsh zsh-autosuggestions zsh-syntax-highlighting
  # Modern CLI replacements (note: bat → batcat, fd → fdfind on Debian)
  bat fd-find ripgrep
  # Dev
  direnv
  # Security
  pinentry-curses
)

# Tools not consistently packaged on older distros (skipped silently if missing):
#   eza, dust, duf, btop, xh, lazygit, lazydocker, git-delta, starship, yq
# Install these via cargo / official installers as needed.

info "Updating apt index..."
sudo apt-get update -qq

info "Installing apt packages: ${APT_PACKAGES[*]}"
if sudo apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"; then
  success "apt packages installed"
else
  warn "Some apt packages failed — continuing"
fi

# ── GitHub CLI (gh) — official apt repo ──────────────────────────────────────

install_gh() {
  if command -v gh &>/dev/null; then
    success "gh already installed"
    return 0
  fi
  info "Installing gh from GitHub's apt repo..."
  local keyring="/usr/share/keyrings/githubcli-archive-keyring.gpg"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of="$keyring" status=none
  sudo chmod go+r "$keyring"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gh && success "gh installed" || warn "gh install failed"
}

install_gh

echo ""
success "Linux package installation complete."
