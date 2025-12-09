# Manual Fix for Spotlight + Raycast Conflict

If both Spotlight and Raycast are opening when you press Command+Space, macOS is ignoring the programmatic disable. You need to manually disable Spotlight's shortcut.

## Quick Fix (Recommended)

1. **Open System Settings** (or System Preferences on older macOS)
2. Go to **Keyboard** → **Keyboard Shortcuts...**
3. Click **Spotlight** in the left sidebar
4. **Uncheck** the box next to "Show Spotlight search"
5. Close System Settings

That's it! Now Command+Space should only open Raycast.

## Why This Happens

macOS sometimes ignores programmatic changes to keyboard shortcuts for security reasons. The automated scripts try to disable it, but macOS may require manual confirmation through the UI.

## Verify It Worked

After unchecking Spotlight:
- Press Command+Space - only Raycast should open
- If Spotlight still opens, try logging out and back in

## Alternative: Change Spotlight's Shortcut

If you want to keep Spotlight but use a different shortcut:
1. In Keyboard Shortcuts → Spotlight
2. Click on "Show Spotlight search"
3. Press a different key combination (e.g., Command+Option+Space)
4. This frees up Command+Space for Raycast

