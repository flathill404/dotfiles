#!/usr/bin/env bash
# macOS productivity & performance tuning.
# Best-effort — individual failures are silently ignored, exit code is always 0.

ok() { printf '\033[32m[  OK]\033[0m  %s\n' "$1"; }
x()  { :; }  # silent no-op on failure

apply() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; fi
}

# ── Dock ─────────────────────────────────────────────────────────────────────

apply "Dock: auto-hide"            defaults write com.apple.dock autohide -bool true
apply "Dock: instant show/hide"    defaults write com.apple.dock autohide-delay -float 0
apply "Dock: fast animation"       defaults write com.apple.dock autohide-time-modifier -float 0.15
apply "Dock: no launch bounce"     defaults write com.apple.dock no-bouncing -bool true
apply "Dock: small size (48px)"    defaults write com.apple.dock tilesize -int 48
apply "Dock: show only open apps"  defaults write com.apple.dock static-only -bool true
apply "Dock: disable recents"      defaults write com.apple.dock show-recents -bool false

# ── Finder ───────────────────────────────────────────────────────────────────

apply "Finder: show hidden files"       defaults write com.apple.finder AppleShowAllFiles -bool true
apply "Finder: show path bar"           defaults write com.apple.finder ShowPathbar -bool true
apply "Finder: show status bar"         defaults write com.apple.finder ShowStatusBar -bool true
apply "Finder: list view default"       defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
apply "Finder: folders on top"          defaults write com.apple.finder _FXSortFoldersFirst -bool true
apply "Finder: no .DS_Store on network" defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
apply "Finder: no .DS_Store on USB"     defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
apply "Finder: no extension change warn" defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
apply "Finder: full POSIX path in title" defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
apply "Finder: search in current folder" defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# ── Keyboard ─────────────────────────────────────────────────────────────────

apply "Keyboard: fastest key repeat"    defaults write NSGlobalDomain KeyRepeat -int 1
apply "Keyboard: shortest initial delay" defaults write NSGlobalDomain InitialKeyRepeat -int 10
apply "Keyboard: disable press-and-hold" defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
apply "Keyboard: disable auto-correct"  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
apply "Keyboard: disable auto-caps"     defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
apply "Keyboard: disable smart dashes"  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
apply "Keyboard: disable smart quotes"  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
apply "Keyboard: disable period shortcut" defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ── Screenshots ──────────────────────────────────────────────────────────────

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR" 2>/dev/null
apply "Screenshots: save to ~/Pictures/Screenshots" defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
apply "Screenshots: PNG format"    defaults write com.apple.screencapture type -string "png"
apply "Screenshots: no shadow"     defaults write com.apple.screencapture disable-shadow -bool true

# ── Mission Control & Spaces ─────────────────────────────────────────────────

apply "Mission Control: fast animation"  defaults write com.apple.dock expose-animation-duration -float 0.1
apply "Mission Control: don't auto-rearrange spaces" defaults write com.apple.dock mru-spaces -bool false
apply "Mission Control: group by app"    defaults write com.apple.dock expose-group-apps -bool true

# ── UI Responsiveness ────────────────────────────────────────────────────────

apply "UI: faster window resize"    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
apply "UI: expand save panel"       defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
apply "UI: expand print panel"      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
apply "UI: quit printer when done"  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
apply "UI: disable crash reporter"  defaults write com.apple.CrashReporter DialogType -string "none"

# ── Trackpad ─────────────────────────────────────────────────────────────────

apply "Trackpad: tap to click"      defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
apply "Trackpad: tap to click (global)" defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Activity Monitor ─────────────────────────────────────────────────────────

apply "Activity Monitor: show all processes"    defaults write com.apple.ActivityMonitor ShowCategory -int 0
apply "Activity Monitor: sort by CPU usage"     defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
apply "Activity Monitor: sort descending"       defaults write com.apple.ActivityMonitor SortDirection -int 0

# ── TextEdit ─────────────────────────────────────────────────────────────────

apply "TextEdit: plain text default"    defaults write com.apple.TextEdit RichText -int 0
apply "TextEdit: open/save as UTF-8"    defaults write com.apple.TextEdit PlainTextEncoding -int 4

# ── Restart affected services ────────────────────────────────────────────────

killall Dock         2>/dev/null || true
killall Finder       2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

ok "macOS speedup complete — some changes require logout/restart to take effect"
exit 0
