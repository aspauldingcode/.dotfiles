#!/bin/bash

osascript -e 'tell application "System Events"
    tell process "Control Center"
        set userSwitcherItem to first menu bar item of menu bar 1 whose description contains "User"
        if (count of userSwitcherItem) > 0 then
            click userSwitcherItem
        else
            display dialog "User Switcher menu item not found." buttons {"OK"} default button "OK"
        end if
    end tell
end tell'
