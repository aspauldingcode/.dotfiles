#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"
# source "$HOME/.config/sketchybar/plugins/add_spaces_sketchybar.sh"

# # Call the function to execute the updates
# update_sketchybar_spaces

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
    sketchybar --set space.$ACTIVE_SPACE_CLEANED icon.highlight=on icon.highlight_color=$base0A
done
sketchybar --set space.$ACTIVE_SPACE_CLEANED icon.highlight=true icon.highlight_color=$base0A