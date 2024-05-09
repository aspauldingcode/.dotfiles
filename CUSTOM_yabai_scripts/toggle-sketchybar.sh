#!/bin/bash

toggle_sketchybar() {
    local hidden_status=$(sketchybar --query bar | jq -r '.hidden')
    local sketchybar_state_file="/tmp/sketchybar_state"

    # Check if the sketchybar state file exists
    if [ ! -f "$sketchybar_state_file" ]; then
        # If the state file doesn't exist, initialize it with the current state
        echo "$hidden_status" > "$sketchybar_state_file"
    fi

    if [ "$1" == "on" ]; then
        if [ "$hidden_status" == "off" ]; then
            echo "Sketchybar is already toggled on"
        else
            sketchybar --bar hidden=off
            yabai -m config external_bar all:45:0
            echo "Sketchybar toggled on"
            echo "on" > "$sketchybar_state_file"  # Write state to file
        fi
    elif [ "$1" == "off" ]; then
        if [ "$hidden_status" == "on" ]; then
            echo "Sketchybar is already toggled off"
        else
            sketchybar --bar hidden=on
            yabai -m config external_bar all:0:0
            echo "Sketchybar toggled off"
            echo "off" > "$sketchybar_state_file"  # Write state to file
        fi
    else
        # No arguments provided, toggle based on current state
        if [ "$hidden_status" == "off" ]; then
            sketchybar --bar hidden=on
            yabai -m config external_bar all:0:0
            echo "Sketchybar toggled off"
            echo "off" > "$sketchybar_state_file"  # Write state to file
        else
            sketchybar --bar hidden=off
            yabai -m config external_bar all:45:0
            echo "Sketchybar toggled on"
            echo "on" > "$sketchybar_state_file"  # Write state to file
        fi
    fi
}

# Example usage
toggle_sketchybar "$1"
