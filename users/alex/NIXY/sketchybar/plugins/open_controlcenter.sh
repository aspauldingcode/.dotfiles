#!/bin/bash

osascript -e 'tell application "System Events"
    tell process "ControlCenter"
        tell menu bar item 2 of menu bar 1
            click
        end tell
    end tell
end tell'
