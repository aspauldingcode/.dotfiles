#!/bin/bash

osascript -e 'tell application "System Events"
    tell process "Control Center"
        set wifiMenuItem to first menu bar item of menu bar 1 whose description contains "Wi" and description contains "Fi"
        if (count of wifiMenuItem) > 0 then
            click item 1 of wifiMenuItem
        else
            display dialog "Wi-Fi menu item not found." buttons {"OK"} default button "OK"
        end if
    end tell
end tell'
