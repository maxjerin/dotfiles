#!/usr/bin/env bash

set -euo pipefail

# Quick script to disable Spotlight and configure Raycast Command+Space
# This can be run independently or as part of the bootstrap process

echo "Configuring Spotlight and Raycast..."

# Ensure the preferences file exists
if [ ! -f ~/Library/Preferences/com.apple.symbolichotkeys.plist ]; then
    defaults read com.apple.symbolichotkeys > /dev/null 2>&1 || true
fi

# Disable Spotlight shortcut (key 64 = Command+Space)
echo "Disabling Spotlight Command+Space shortcut..."
PLIST_FILE="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

# Ensure file exists
if [ ! -f "$PLIST_FILE" ]; then
    defaults read com.apple.symbolichotkeys > /dev/null 2>&1 || true
fi

# Method 1: Use PlistBuddy
if /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:64" "$PLIST_FILE" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled bool false" "$PLIST_FILE"
    echo "✓ Spotlight shortcut disabled via PlistBuddy"
else
    echo "⚠ Spotlight shortcut key 64 not found, creating it..."
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64 dict" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:enabled bool false" "$PLIST_FILE"
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value dict" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:type string standard" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters array" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:0 integer 32" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:1 integer 49" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:2 integer 1048576" "$PLIST_FILE" 2>/dev/null || true
    echo "✓ Spotlight shortcut created and disabled"
fi

# Method 2: Also use defaults write as backup (more reliable)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{enabled = 0; value = { parameters = (32, 49, 1048576); type = 'standard'; }; }" 2>/dev/null || true
echo "✓ Spotlight shortcut disabled via defaults write"

# Method 3: Use AppleScript to programmatically uncheck Spotlight shortcut in System Settings
# This is the most reliable method as it actually changes the UI setting
echo "Disabling Spotlight shortcut via System Settings..."
osascript <<'EOF' || true
tell application "System Settings"
    activate
end tell
delay 1
tell application "System Events"
    tell process "System Settings"
        -- Navigate to Keyboard Shortcuts
        try
            click button "Keyboard Shortcuts…" of group 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
            delay 1
            -- Select Spotlight in sidebar
            click row 8 of outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
            delay 0.5
            -- Uncheck "Show Spotlight search"
            set spotlightCheckbox to checkbox 1 of group 1 of scroll area 2 of group 1 of splitter group 1 of group 1 of window 1
            if value of spotlightCheckbox is 1 then
                click spotlightCheckbox
                delay 0.5
            end if
            -- Close System Settings
            keystroke "w" using command down
        on error
            -- If automation fails, just close System Settings
            try
                keystroke "w" using command down
            end try
        end try
    end tell
end tell
EOF
echo "✓ Attempted to disable via System Settings UI"

# Configure Raycast if installed
if [ -d "/Applications/Raycast.app" ]; then
    echo "Configuring Raycast to use Command+Space..."
    defaults write com.raycast.macos raycastGlobalHotkey "Command-49"
    defaults write com.raycast.macos initialSpotlightHotkey "Command-49"
    echo "✓ Raycast hotkey set to Command+Space"

    # Kill Raycast if running to apply changes
    killall Raycast 2>/dev/null || true
    echo "✓ Raycast restarted to apply changes"
else
    echo "⚠ Raycast not found at /Applications/Raycast.app"
    echo "  Please install Raycast first, then run this script again"
fi

# Disable Spotlight indexing and search results
echo "Disabling Spotlight indexing and search results..."
sudo mdutil -i off / 2>/dev/null || echo "⚠ Could not disable Spotlight indexing (may need sudo password)"
sudo mdutil -i off /System/Volumes/Data 2>/dev/null || true

# Clear and erase existing Spotlight indexes
echo "Clearing existing Spotlight indexes..."
sudo mdutil -E / 2>/dev/null || true
sudo mdutil -E /System/Volumes/Data 2>/dev/null || true

# Remove Spotlight index directories (more aggressive)
echo "Removing Spotlight index directories..."
sudo rm -rf /.Spotlight-V100 2>/dev/null || true
sudo rm -rf /System/Volumes/Data/.Spotlight-V100 2>/dev/null || true

# Disable indexing via defaults
defaults write com.apple.Spotlight.plist indexingEnabled -bool false 2>/dev/null || true

# Replace entire orderedItems array with all categories disabled
echo "Disabling all Spotlight search result categories..."
PLIST_FILE="$HOME/Library/Preferences/com.apple.Spotlight.plist"

# Delete existing orderedItems and create new array with all disabled
defaults delete com.apple.Spotlight orderedItems 2>/dev/null || true

# Create array with all categories disabled at once
defaults write com.apple.Spotlight orderedItems -array \
  '{enabled = 0; name = APPLICATIONS;}' \
  '{enabled = 0; name = BOOKMARKS;}' \
  '{enabled = 0; name = CONTACT;}' \
  '{enabled = 0; name = DIRECTORIES;}' \
  '{enabled = 0; name = DOCUMENTS;}' \
  '{enabled = 0; name = EVENT_TODO;}' \
  '{enabled = 0; name = FONTS;}' \
  '{enabled = 0; name = IMAGES;}' \
  '{enabled = 0; name = MENU_CONVERSION;}' \
  '{enabled = 0; name = MENU_DEFINITION;}' \
  '{enabled = 0; name = MENU_EXPRESSION;}' \
  '{enabled = 0; name = MENU_OTHER;}' \
  '{enabled = 0; name = MENU_SPOTLIGHT_SUGGESTIONS;}' \
  '{enabled = 0; name = MESSAGES;}' \
  '{enabled = 0; name = MOVIES;}' \
  '{enabled = 0; name = MUSIC;}' \
  '{enabled = 0; name = PDF;}' \
  '{enabled = 0; name = PRESENTATIONS;}' \
  '{enabled = 0; name = SPREADSHEETS;}' \
  '{enabled = 0; name = SYSTEM_PREFS;}' \
  '{enabled = 0; name = SOURCE;}' \
  '{enabled = 0; name = WEB_PAGES;}' 2>/dev/null || true

# Disable Spotlight indexing service
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist 2>/dev/null || true

# Kill Spotlight processes
killall Spotlight 2>/dev/null || true

echo "✓ Spotlight indexing and search results disabled"

# Restart Dock and SystemUIServer to apply Spotlight changes
echo "Restarting Dock and SystemUIServer to apply Spotlight changes..."
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo ""
echo "Configuration complete!"
echo ""
echo "⚠️  IMPORTANT: macOS may ignore programmatic keyboard shortcut changes."
echo "   You MUST manually disable Spotlight's shortcut:"
echo ""
echo "   1. Open System Settings → Keyboard → Keyboard Shortcuts"
echo "   2. Click 'Spotlight' in the left sidebar"
echo "   3. UNCHECK 'Show Spotlight search'"
echo "   4. Close System Settings"
echo ""
echo "   See MANUAL_SPOTLIGHT_FIX.md for detailed instructions."
echo ""
echo "After manually disabling Spotlight:"
echo "  - Press Command+Space - only Raycast should open"
echo "  - If both still open, log out and back in"

