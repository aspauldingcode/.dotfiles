#!/bin/bash

move_window_and_focus_space() {
    local space_index="$1"

    # Move the focused window to the specified space
    yabai -m window --space "_$space_index"

    # Focus on the specified space
    yabai -m space --focus "_$space_index"
}

# Call the function with a space index as an argument
move_window_and_focus_space "$1"
