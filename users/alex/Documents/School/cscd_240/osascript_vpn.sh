#!/bin/bash

# Script to open the GlobalProtect VPN menubar applet and connect

echo "Attempting to interact with GlobalProtect VPN..."

# Make sure GlobalProtect is running
open -a GlobalProtect
sleep 2

# Use osascript to find and click the GlobalProtect menubar icon
osascript <<EOF
tell application "System Events"
    # First try the direct approach with the GlobalProtect process
    try
        tell process "GlobalProtect"
            # Click the menu bar item to open the dropdown
            click menu bar item 1 of menu bar 1
            delay 1
            
            # Try to find and click "Connect" in the dropdown menu
            tell menu 1 of menu bar item 1 of menu bar 1
                click menu item "Connect"
            end tell
        end tell
    on error
        # If that fails, try an alternative approach similar to your other scripts
        tell application "System Events"
            tell process "GlobalProtect"
                # Try menu bar 2 as in your current script
                click menu bar item 1 of menu bar 2
                delay 1
                
                # Try to find and click "Connect"
                tell menu 1 of menu bar item 1 of menu bar 2
                    click menu item "Connect"
                end tell
            end tell
        end tell
    end try
end tell
EOF

echo "GlobalProtect operation completed."