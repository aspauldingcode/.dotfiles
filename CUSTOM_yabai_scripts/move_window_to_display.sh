#!/bin/bash

# Function to query displays and get the total count
get_displays_count() {
    local displays_count
    displays_count=$(yabai -m query --displays | jq length)
    echo "$displays_count"
}

# Function to move window to display by label
move_window_to_display_by_label() {
    local display_label="$1"
    yabai -m window --display "$display_label"
}

# Main script logic
input="$1"
displays_count=$(get_displays_count)

if [[ "$input" =~ ^_[0-9]+$ ]]; then
    move_window_to_display_by_label "$input"
elif [[ "$input" =~ ^[0-9]+$ ]]; then
    if (( input > 0 && input <= displays_count )); then
        move_window_to_display_by_label "_$input"
    elif (( displays_count == 1 )); then
        echo "Warning: Display $input is out of range. There is only 1 display."
    else
        echo "Warning: Display $input is out of range. There are only $displays_count displays."
    fi
else
    echo "Invalid input. Please provide a valid integer, n."
fi
