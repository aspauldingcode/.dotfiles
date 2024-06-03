#!/bin/bash

osascript -e 'tell application "System Events"
    tell process "Control Center"
        set batteryMenuItem to menu bar items of menu bar 1 whose description contains "Battery"
        if (count of batteryMenuItem) > 0 then
            click item 1 of batteryMenuItem
        else
            display dialog "Battery menu item not found." buttons {"OK"} default button "OK"
        end if
    end tell
end tell'
