#!/bin/bash

state_file="/tmp/gaps_state"

# Initialize the state file if it doesn't exist
if [ ! -f "$state_file" ]; then
    echo "off" > "$state_file"
fi

# Read the current state from the state file
gaps_state=$(cat "$state_file")

toggle() {
    if [ "$gaps_state" == "off" ]; then
        on
        echo "on" > "$state_file"
    else
        off
        echo "off" > "$state_file"
    fi
}

on() {
    yabai -m config top_padding     15
    yabai -m config bottom_padding  15
    yabai -m config left_padding    15
    yabai -m config right_padding   15
    yabai -m config window_gap      15
}

off() {
    yabai -m config top_padding     0
    yabai -m config bottom_padding  0
    yabai -m config left_padding    0
    yabai -m config right_padding   0
    yabai -m config window_gap      0
}

if [ "$#" -eq 0 ]; then
    toggle
elif [ "$1" == "on" ]; then
    on
    echo "on" > "$state_file"
elif [ "$1" == "off" ]; then
    off
    echo "off" > "$state_file"
else
    echo "Invalid argument. Usage: $0 [on|off]"
fi

