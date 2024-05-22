#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/plugins/sway_spaces.sh"

# Query for the total number of displays
TOTAL_DISPLAYS=$(yabai -m query --displays | jq 'length')

# # Reset highlights for all space items
# for id in "${all_space_ids[@]}"; do
#     sketchybar --set $id icon.highlight=off
#     echo -e "reset highlights running now"
# done

# Loop through each display
for ((display=1; display<=$TOTAL_DISPLAYS; display++)); do
    # Query for the active space on the current display
    ACTIVE_SPACE_LABEL=$(yabai -m query --spaces --display $display | jq -r '.[] | select(.["is-visible"] == true) | .label')
    
    # Extract the numeric part of the label, removing the underscore
    ACTIVE_SPACE_CLEANED="${ACTIVE_SPACE_LABEL#_}"
    
    # Highlight the active space on SketchyBar using the cleaned label
    sketchybar --set space.$ACTIVE_SPACE_CLEANED icon.highlight=on icon.highlight_color=$ORANGE
done
sketchybar --set space.$ACTIVE_SPACE_CLEANED icon.highlight=true icon.highlight_color=$ORANGE

#yabai_i3_switch # in charge of detecting if we are on a x11.bin window or not. Fixes mouse resize.
#echo -e "\n\n\n\n\n\tEXECUTING yabai_i3_switch NOW!!!!\n\n\n\n\n"