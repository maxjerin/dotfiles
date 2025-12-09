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

# Restart Dock and SystemUIServer to apply Spotlight changes
echo "Restarting Dock and SystemUIServer to apply Spotlight changes..."
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo ""
echo "Configuration complete!"
echo "Try pressing Command+Space - it should open Raycast instead of Spotlight."
echo ""
echo "If it doesn't work:"
echo "1. Make sure Raycast is running"
echo "2. Open Raycast preferences (⌘,) and verify the hotkey is set to ⌘ Space"
echo "3. You may need to log out and back in for Spotlight changes to take effect"

