#!/bin/bash

# Function to toggle the macOS menu bar
toggle_menubar() {
    current_opacity=$(osascript -e 'tell application "System Events" to tell dock preferences to get autohide menu bar')
    if [[ "$current_opacity" == "true" ]]; then
        osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
        echo "Menu bar turned ON"
    else
        osascript -e 'delay 0.5' -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
        echo "Menu bar turned OFF"
    fi
}

# Main
if [[ "$#" -eq 0 ]]; then
    toggle_menubar
elif [[ "$#" -eq 1 && ($1 == "on" || $1 == "off") ]]; then
    if [[ "$1" == "on" ]]; then
        osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
        echo "Menu bar turned ON"
    else
        osascript -e 'delay 0.5' -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
        echo "Menu bar turned OFF"
    fi
else
    echo "Usage: $0 <on | off>"
    exit 1
fi

