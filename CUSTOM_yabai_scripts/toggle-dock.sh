#!/bin/bash

dock_state_file="/tmp/dock_state"

toggle_dock() {
    local dock_status=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')

    if [ "$1" == "--nolog" ]; then
        # If --nolog argument is provided, do not save state to file
        shift  # Remove --nolog argument from the argument list
        nolog=true
    fi

    if [ $# -eq 0 ]; then
        # No arguments provided, toggle based on current state
        if [ "$dock_status" = "true" ]; then
            osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
            echo "Dock toggled on"
            if [ "$nolog" != true ]; then
                echo "off" > "$dock_state_file"  # Save state to file
            fi
        else
            osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
            echo "Dock toggled off"
            if [ "$nolog" != true ]; then
                echo "on" > "$dock_state_file"  # Save state to file
            fi
        fi
    elif [ "$1" = "on" ]; then
        if [ "$dock_status" = "true" ]; then
            echo "Dock is already toggled on"
        else
            osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
            echo "Dock toggled on"
            if [ "$nolog" != true ]; then
                echo "off" > "$dock_state_file"  # Save state to file
            fi
        fi
    elif [ "$1" = "off" ]; then
        if [ "$dock_status" = "false" ]; then
            echo "Dock is already toggled off"
        else
            osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
            echo "Dock toggled off"
            if [ "$nolog" != true ]; then
                echo "on" > "$dock_state_file"  # Save state to file
            fi
        fi
    else
        echo "Invalid argument. Usage: $0 [on | off] [--nolog]"
        exit 1
    fi
}

# Example usage
toggle_dock "$@"
