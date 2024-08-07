#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

reorder_space_items() {
    # Get all space items and sort them numerically
    local space_items=$(sketchybar --query bar | $jq -r '.items[] | select(startswith("space."))' | sort -V)

    # Reorder space items numerically
    sketchybar --reorder $space_items
}

function update_sketchybar_spaces() {
    # Get all displays
    local displays=$($yabai -m query --displays | $jq -r '.[].index')

    for display in $displays; do
        # Get the full label from the function and extract only the numeric part for the current display
        full_label=$(source $PLUGIN_DIR/sway_spaces.sh; check_current_active_space_label $display)
        active_space_label=$(echo "$full_label" | /usr/bin/sed 's/[^0-9]*//g')  # Remove all non-numeric characters

        relevant_spaces=($($PLUGIN_DIR/print_spaces_sketchybar.sh $display | tr ' ' '\n' | /usr/bin/sed 's/^_//'))
        relevant_spaces=($(echo "${relevant_spaces[@]}" | tr ' ' '\n' | sort -n))  # Sort spaces numerically

        sketchybar_spaces=($(sketchybar --query bar | $jq -r '.items[] | select(startswith("space."))'))

        # Create an associative array for space colors
        declare -A space_colors

        # Set default color for all spaces and special color for active space
        for space in "${relevant_spaces[@]}"; do
            space_colors[$space]="$base05"
        done
        space_colors[$active_space_label]="$base0A"

        for space in "${relevant_spaces[@]}"; do
            label=$(echo "$space" | /usr/bin/sed 's/^_//')  # Ensure no leading underscore
            color="$base05"  # Default color
            [[ "$label" == "$active_space_label" ]] && color="$base0A"  # Set color to base0A if it's the active space

            # Set the properties of the cloned space item
            sketchybar --set space.${display}.${label} \
                            label="$label" \
                            label.color="$color" \
                            click_script="$yabai -m space --focus _$label" \
                            padding_left=5 \
                            padding_right=5 \
                            drawing=on
                            
            # Clone the existing space item and rename the cloned item
            sketchybar --clone space.${display}.${label} space after

            # Remove the original space item from the list of spaces
            sketchybar_spaces=("${sketchybar_spaces[@]/space.${display}.${label}/}")
        done

        # Call the function to reorder space items
        reorder_space_items

        # Remove any remaining stale space items for this display
        for space_id in "${sketchybar_spaces[@]}"; do
            if [[ -n "$space_id" && "$space_id" == space.${display}.* ]]; then
                sketchybar --remove "$space_id"
            fi
        done
    done

    source $PLUGIN_DIR/sway_spaces.sh
    # update spaces using yabai init program
    echo -e "\nGenerating Unique Labels:"
    generate_unique_labels

    echo -e "\nRemoving Unnecessary Spaces:"
    remove_unimportant_spaces

    echo -e "\nReorder Display Labels Accordingly:"
    reorder_displays "--auto" # save the pain and agony of display ordering

    echo -e "\nDisplay Information with Spaces Information:"
    read_spaces_on_display_n_for_all_displays

    echo -e "\nPrint Space Labels:"
    read_all_spaces

    echo -e "\nReordering space items"
}

echo -e "\n\n\nRunning update_sketchybar_spaces\n\n\n"
update_sketchybar_spaces