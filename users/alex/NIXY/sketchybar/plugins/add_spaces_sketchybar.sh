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
    # Get the full label from the function and extract only the numeric part
    full_label=$(source $PLUGIN_DIR/sway_spaces.sh; check_current_active_space_label)
    active_space_label=$(echo "$full_label" | /usr/bin/sed 's/[^0-9]*//g')  # Remove all non-numeric characters

    relevant_spaces=($($PLUGIN_DIR/print_spaces_sketchybar.sh | tr ' ' '\n' | /usr/bin/sed 's/^_//'))
    relevant_spaces=($(echo "${relevant_spaces[@]}" | tr ' ' '\n' | sort -n))  # Sort spaces numerically

    sketchybar_spaces=($(sketchybar --query bar | $jq -r '.items[] | select(startswith("space."))'))

    # Create an associative array for space colors
    declare -A space_colors

    # Set default color for all spaces and special color for active space
    for space in "${relevant_spaces[@]}"; do
        space_colors[$space]="$WHITE"
    done
    space_colors[$active_space_label]="$ORANGE"

    # Prepare the command string
    command_string=""

    # Build the command string for all spaces
    for space in "${relevant_spaces[@]}"; do
        label=${space#_}  # Remove leading underscore if present
        color=${space_colors[$label]}

        command_string+="--set space.$label label=$label padding_right=5 padding_left=5 label.color=$color "
        command_string+="click_script=\"$yabai -m space --focus _$label\" "
        command_string+="padding_left=5 padding_right=5 drawing=on "
        command_string+="--clone space.$label space after "

        # Remove the space from sketchybar_spaces array
        sketchybar_spaces=("${sketchybar_spaces[@]/space.$label/}")
    done

    # Execute the command
    sketchybar $command_string
    
    # Call the function to reorder space items
    reorder_space_items

    # Remove any remaining stale space items
    for space_id in "${sketchybar_spaces[@]}"; do
        if [[ -n "$space_id" ]]; then
            sketchybar --remove "$space_id"
        fi
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

    echo $active_space_label

    echo -e "\nReordering space items"
}

echo -e "\n\n\nRunning update_sketchybar_spaces\n\n\n"
update_sketchybar_spaces
