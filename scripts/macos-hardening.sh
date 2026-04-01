#!/usr/bin/env bash
# macOS security hardening defaults.
# Safe to run multiple times — each command is idempotent.

set -euo pipefail

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }

# ── Firewall ─────────────────────────────────────────────────────────────────
info "Enabling application firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >/dev/null 2>&1
info "Enabling stealth mode..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on >/dev/null 2>&1
success "Firewall configured"

# ── Gatekeeper ───────────────────────────────────────────────────────────────
info "Ensuring Gatekeeper is enabled..."
sudo spctl --master-enable 2>/dev/null
success "Gatekeeper enabled"

# ── Screen Lock ──────────────────────────────────────────────────────────────
info "Requiring password immediately on sleep/screensaver..."
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
success "Screen lock configured"

# ── Finder Security ──────────────────────────────────────────────────────────
info "Showing all file extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
success "File extensions visible"

# ── Remote Access ────────────────────────────────────────────────────────────
info "Disabling remote login (SSH server)..."
sudo systemsetup -setremotelogin off 2>/dev/null || true
success "Remote login disabled"

# ── Automatic Updates ────────────────────────────────────────────────────────
info "Enabling automatic security updates..."
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
success "Automatic updates configured"

# ── Safari ───────────────────────────────────────────────────────────────────
info "Disabling Safari auto-open downloads..."
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false 2>/dev/null || true
success "Safari hardened"

# ── FileVault Check ──────────────────────────────────────────────────────────
if fdesetup status | grep -q "On"; then
  success "FileVault is enabled"
else
  info "FileVault is OFF — enable it via System Settings > Privacy & Security > FileVault"
fi

echo ""
success "macOS hardening complete."
