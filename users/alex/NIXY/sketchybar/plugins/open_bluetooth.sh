#!/bin/bash

osascript -e 'tell application "System Events"
    tell process "Control Center"
        set bluetoothMenuItem to menu bar items of menu bar 1 whose description contains "Bluetooth"
        if (count of bluetoothMenuItem) > 0 then
            click item 1 of bluetoothMenuItem
        else
            display dialog "Bluetooth menu item not found." buttons {"OK"} default button "OK"
        end if
    end tell
end tell'