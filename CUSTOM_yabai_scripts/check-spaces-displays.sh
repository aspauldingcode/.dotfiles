#!/bin/bash

# Query for spaces with windows
spaces_with_windows=($(yabai -m query --spaces | jq -r '.[] | select(.windows | length > 0) | .index'))

# Query for the active space
active_space=$(yabai -m query --spaces --space | jq -r '.index')

# active space per display
# Query for the total number of displays
total_displays=$(yabai -m query --displays | jq 'length')

# Initialize an array to store active display spaces
active_display_spaces=()

# Loop through each display
for ((display=1; display<=$total_displays; display++)); do
    # Query for spaces on the current display that are visible
    spaces=$(yabai -m query --spaces --display $display | jq -r '.[] | select(.["is-visible"] == true) | .index')

    # Add visible spaces to the active_display_spaces array
    for space in $spaces; do
        active_display_spaces+=("$space")
    done
done

# Combine spaces with windows and active spaces on all displays
print=($(echo "${spaces_with_windows[@]}" "${active_display_spaces[@]}" | tr ' ' '\n' | sort -nu))

echo "${print[@]}"

# Print the debug information
# echo "Debug Output:"
# echo "spaces_with_windows: ${spaces_with_windows[@]}"
# echo "active_space: $active_space"
# echo "active_display_spaces: ${active_display_spaces[@]}"
#
# # Print the print array
# echo "print[]: [ ${print[@]} ]"
