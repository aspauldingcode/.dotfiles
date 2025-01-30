#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

app_name=$1
button=${2:-$BUTTON}
modifier=${3:-$MODIFIER}

# Main case statement
case $app_name in
    "apple")
        case $button in
            "left")
                open -a "System Settings"
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "Finder" to click menu bar item 1 of menu bar 1'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "alttab")
        case $button in
            "left")
                open -a AltTab
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "AltTab"
                    click menu bar item 1 of menu bar 2
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "macosinstantview")
        case $button in
            "left")
                open -a macOS\ InstantView
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "macOS InstantView"
                    click menu bar item 1 of menu bar 2
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "unnaturalscrollwheels")
        case $button in
            "left")
                open -a UnnaturalScrollWheels
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "UnnaturalScrollWheels"
                    click menu bar item 1 of menu bar 2
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "flameshot")
        case $button in
            "left")
                $flameshot gui
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "Flameshot"
                    click menu bar item 1 of menu bar 2
                end tell'   
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "karabiner-menu")
        case $button in
            "left")
                open -a Karabiner-EventViewer
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "Karabiner-Menu"
                    click menu bar item 1 of menu bar 1
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "backgroundmusic")
        case $button in
            "left")
                open -a Background\ Music
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "Background Music"
                    click menu bar item 1 of menu bar 1
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "controlcenter")
        case $button in
            "left")
                open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "ControlCenter"
                    tell menu bar item 2 of menu bar 1
                        click
                    end tell
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "notificationcenter")
        case $button in
            "left")
                open "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
                ;;
            "right")
                osascript -e '
                tell application "System Events"
                    tell process "Control Center"
                        click menu bar item 1 of menu bar 1
                    end tell
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "bluetooth")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.preferences.Bluetooth
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "ControlCenter"
                    tell (first menu bar item of menu bar 1 whose description contains "Bluetooth")
                        key down option
                        click
                        key up option
                    end tell
                end tell'
                
                # $blueutil --power toggle
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "userswitcher")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.preferences.users
                ;;
            "right")
                osascript -e '
                tell application "System Events"
                    tell application process "Control Center"
                        tell (first menu bar item of menu bar 1 whose description contains "user")
                            perform action "AXPress"
                        end tell
                    end tell
                end tell' 
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "wifi")
        case $button in
            "left")
                open "x-apple.systempreferences:com.apple.preference.network?Wi-Fi"
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "ControlCenter"
                    tell (first menu bar item of menu bar 1 whose description contains "Wi" and description contains "Fi")
                        key down option
                        click
                        key up option
                    end tell
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "airdrop")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.systempreferences
                ;;
            "right")
                osascript -e 'tell application "System Events" to tell process "Control Center"
                    click (first menu bar item of menu bar 1 whose description contains "AirDrop")
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "battery")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.preference.battery
                ;;
            "right")
                pmset -g batt | grep -o "[0-9]*%" | notify-send
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "cpu")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.systempreferences
                ;;
            "right")
                osascript -e 'tell application "System Events"
                    tell process "Activity Monitor"
                        keystroke "3" using command down
                    end tell
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
        ;;
    "memory")
        case $button in
            "left")
                open x-apple.systempreferences:com.apple.systempreferences
                ;;
            "right")
                osascript -e 'tell application "System Events"
                    tell process "Activity Monitor"
                        keystroke "2" using command down
                    end tell
                end tell'
                ;;
            "other")
                osascript -e 'display dialog "Button is: '"$button"'"'
                osascript -e 'display dialog "Modifier is: '"$modifier"'"'
                ;;
        esac
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
