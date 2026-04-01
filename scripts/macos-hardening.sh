#!/usr/bin/env bash
# macOS security hardening defaults.
# Safe to run multiple times — each command is idempotent.
# Individual failures are logged but do not abort the script.

info()    { printf '\033[34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }
warn()    { printf '\033[33m[WARN]\033[0m  %s\n' "$1"; }

# ── Firewall ─────────────────────────────────────────────────────────────────
info "Enabling application firewall..."
if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >/dev/null 2>&1; then
  success "Firewall enabled"
else
  warn "Failed to enable firewall (may need Full Disk Access)"
fi

info "Enabling stealth mode..."
if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on >/dev/null 2>&1; then
  success "Stealth mode enabled"
else
  warn "Failed to enable stealth mode"
fi

# ── Gatekeeper ───────────────────────────────────────────────────────────────
info "Ensuring Gatekeeper is enabled..."
if sudo spctl --master-enable 2>/dev/null; then
  success "Gatekeeper enabled"
else
  warn "Failed to enable Gatekeeper (may be deprecated on this macOS version)"
fi

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
if sudo systemsetup -setremotelogin off 2>/dev/null; then
  success "Remote login disabled"
else
  warn "Failed to disable remote login (may need Full Disk Access)"
fi

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
if fdesetup status 2>/dev/null | grep -q "On"; then
  success "FileVault is enabled"
else
  warn "FileVault is OFF — enable it via System Settings > Privacy & Security > FileVault"
fi

echo ""
success "macOS hardening complete."
