#!/bin/bash

app_name=$1

case $app_name in
    "flameshot")
        osascript -e 'tell application "System Events" to tell process "Flameshot"
            click menu bar item 1 of menu bar 2
        end tell'
        ;;
    "alttab")
        osascript -e 'tell application "System Events" to tell process "AltTab"
            click menu bar item 1 of menu bar 2
        end tell'
        ;;
    "macosinstantview")
        osascript -e 'tell application "System Events" to tell process "macOS InstantView"
            click menu bar item 1 of menu bar 2
        end tell'
        ;;
    "unnaturalscrollwheels")
        osascript -e 'tell application "System Events" to tell process "UnnaturalScrollWheels"
            click menu bar item 1 of menu bar 2
        end tell'
        ;;
    "karabiner-menu")
        osascript -e 'tell application "System Events" to tell process "Karabiner-Menu"
            click menu bar item 1 of menu bar 1
        end tell'
        ;;
    "backgroundmusic")
        osascript -e 'tell application "System Events" to tell process "Background Music"
            click menu bar item 1 of menu bar 1
        end tell'
        ;;
    "controlcenter")
        osascript -e 'tell application "System Events" to tell process "ControlCenter"
            tell menu bar item 2 of menu bar 1
                click
            end tell
        end tell'
        ;;
    "bluetooth")
        osascript -e 'tell application "System Events" to tell process "Control Center"
            set bluetoothMenuItem to menu bar items of menu bar 1 whose description contains "Bluetooth"
            if (count of bluetoothMenuItem) > 0 then
                click item 1 of bluetoothMenuItem
            else
                display dialog "Bluetooth menu item not found." buttons {"OK"} default button "OK"
            end if
        end tell'
        ;;
    "userswitcher")
        osascript -e 'tell application "System Events" to tell process "Control Center"
            set userSwitcherItem to first menu bar item of menu bar 1 whose description contains "User"
            if (count of userSwitcherItem) > 0 then
                click userSwitcherItem
            else
                display dialog "User Switcher menu item not found." buttons {"OK"} default button "OK"
            end if
        end tell'
        ;;
    "wifi")
        osascript -e 'tell application "System Events" to tell process "Control Center"
            set wifiMenuItem to first menu bar item of menu bar 1 whose description contains "Wi" and description contains "Fi"
            if (count of wifiMenuItem) > 0 then
                click item 1 of wifiMenuItem
            else
                display dialog "Wi-Fi menu item not found." buttons {"OK"} default button "OK"
            end if
        end tell'
        ;;
    "battery")
        osascript -e 'tell application "System Events" to tell process "Control Center"
            set batteryMenuItem to menu bar items of menu bar 1 whose description contains "Battery"
            if (count of batteryMenuItem) > 0 then
                click item 1 of batteryMenuItem
            else
                display dialog "Battery menu item not found." buttons {"OK"} default button "OK"
            end if
        end tell'
        ;;
    *)
        echo "Application not found."
        ;;
esac
