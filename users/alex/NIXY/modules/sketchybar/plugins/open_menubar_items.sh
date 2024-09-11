#!/bin/bash

app_name=$1

case $app_name in
    "kde-connect")
        osascript -e 'tell application "System Events" to tell process "KDE Connect"
            click menu bar item 1 of menu bar 2
        end tell'
        ;;
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
        open x-apple.systempreferences:com.apple.preferences.Bluetooth
        ;;
    "userswitcher")
        open x-apple.systempreferences:com.apple.preferences.users
        ;;
    "wifi")
        open x-apple.systempreferences:com.apple.preference.network
        ;;
    "airdrop")
        osascript -e 'tell application "System Events" to tell process "Control Center"
            click (first menu bar item of menu bar 1 whose description contains "AirDrop")
        end tell'
        ;;
    "battery")
        open x-apple.systempreferences:com.apple.preference.battery
        ;;
    *)
        echo "Application not found."
        ;;
esac

# Important apple preferences shit


# Open Storage, in System Settings: General:

# open x-apple.systempreferences:com.apple.settings.Storage


# Open Software Update, in System Settings: General:

# open x-apple.systempreferences:com.apple.Software-Update-Settings.extension


# Open General, in System Settings:

# open x-apple.systempreferences:com.apple.systempreferences.GeneralSettings


# Open Privacy & Security, in System Settings:

# open x-apple.systempreferences:com.apple.preference.security


# Open Privacy & Security, in System Settings:

# open x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension


# Open Startup Disk, in System Settings: General:

# open x-apple.systempreferences:com.apple.preference.startupdisk


# Open Startup Disk, in System Settings: General:

# open x-apple.systempreferences:com.apple.Startup-Disk-Settings.extension


# Open Displays, in System Settings:

# open x-apple.systempreferences:com.apple.preference.displays


# Open Wallpaper, in System Settings:

# open x-apple.systempreferences:com.apple.Wallpaper-Settings.extension


# Open Network, in System Settings:

# open x-apple.systempreferences:com.apple.preference.network


# Open Network, in System Settings:

# open x-apple.systempreferences:com.apple.Network-Settings.extension


# Open Profiles, in System Settings: Privacy & Security:

# open x-apple.systempreferences:com.apple.Profiles-Settings.extension


# Open Transfer or Reset, in System Settings: General:

# open x-apple.systempreferences:com.apple.Transfer-Reset-Settings.extension


# Open Date & Time, in System Settings: General:

# open x-apple.systempreferences:com.apple.Date-Time-Settings.extension


# Open About, in System Settings: General:

# open x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension


# Open Language & Region, in System Settings: General:

# open x-apple.systempreferences:com.apple.Localization-Settings.extension


# Open Login Items, in System Settings: General:

# open x-apple.systempreferences:com.apple.LoginItems-Settings.extension


# Open Sharing, in System Settings: General:

# open x-apple.systempreferences:com.apple.Sharing-Settings.extension


# Open AirDrop & Handoff, in System Settings: General

# open x-apple.systempreferences:com.apple.AirDrop-Handoff-Settings.extension


# Open Time Machine, in System Settings: General

# open x-apple.systempreferences:com.apple.Time-Machine-Settings.extension


# Open Appearance, in System Settings:

# open x-apple.systempreferences:com.apple.Appearance-Settings.extension


# Open Apple ID, in System Settings:

# open x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane
