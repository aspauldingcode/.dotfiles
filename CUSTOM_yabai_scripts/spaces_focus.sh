#!/bin/bash

# Source the yabai_labeler.sh script from ~/.dotfiles
source ~/.dotfiles/yabai_labeler.sh

# Function to rename a space
rename_space() {
    local space_index="$1"
    local label="_$space_index"

    if [ "$current_label" != "_$1" ]; then
        
        echo -e "creating a new space"
        # Create a new space
        yabai -m space --create

        echo -e "focusing on space $index"
# Query for the number of displays using yabai
display_count=$(yabai -m query --displays | jq length)

# If there's more than one display, create a new space and focus on it
if [ "$display_count" -gt 1 ]; then
    yabai -m space --create && \
    index="$(yabai -m query --spaces --display | jq 'map(select(."native-fullscreen" == 0))[-1].index')" && \
    yabai -m space --focus "${index}"
else
    # If there's only one display, simply create a new space and focus on it
    yabai -m space --create && yabai -m space --focus last
fi



        # Focus on the new space
        yabai -m space --focus "$index"
            
        echo -e "removing unimportant spaces"
        # Call the remove_unimportant_spaces function
        remove_unimportant_spaces

        echo -e "labeling space index $index with label $label..."
        # Label the new space with the desired label
        yabai -m space "$index" --label "$label"
    fi
}

# Call the function with the desired space index and label as arguments
rename_space "$1"
