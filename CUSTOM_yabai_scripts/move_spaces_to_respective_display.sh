#!/bin/bash

# Get the number of displays
num_displays=$(yabai -m query --displays | jq length)

# Function to ensure there is at least one space available on each display
ensure_spaces_available() {
    for (( display_index=1; display_index<=num_displays; display_index++ )); do
        local display_spaces=$(yabai -m query --spaces --display "$display_index" | jq length)
        if [ "$display_spaces" -eq 0 ]; then
            yabai -m space --create --display "$display_index"
        fi
    done
}

# Function to move space to respective display by label
move_space_to_display_by_label() {
    local label_index="$1"
    local display_label="_$label_index"
    local display_info=$(yabai -m query --displays | jq -r ".[] | select(.label | startswith(\"$display_label\"))")
    if [ -n "$display_info" ]; then
        local display_id=$(echo "$display_info" | jq -r ".id")
        yabai -m space "$label_index" --display "$display_id"
    else
        echo "Display '$display_label' not found or available."
    fi
}

# Main script logic
ensure_spaces_available
for (( space_index=1; space_index<=num_displays; space_index++ )); do
    move_space_to_display_by_label "$space_index"
done
