#!/bin/bash

# Define the AppleScript
APPLESCRIPT='
tell application "System Preferences"
    activate
    set current pane to pane "com.apple.preference.universalaccess"
    delay 1
    tell application "System Events"
        tell process "System Preferences"
            click pop up button 2 of tab group 1 of window 1
            click menu item "Display" of menu 1 of pop up button 2 of tab group 1 of window 1
            delay 1
            click checkbox "Reduce transparency" of tab group 1 of window 1
        end tell
    end tell
    delay 1
    quit
end tell
'

# Execute the AppleScript using osascript
osascript -e "$APPLESCRIPT"
