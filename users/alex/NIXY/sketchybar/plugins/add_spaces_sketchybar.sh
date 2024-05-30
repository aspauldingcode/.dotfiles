#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

function update_sketchybar_spaces() {
    # Get the full label from the function and extract only the numeric part
    full_label=$(source $PLUGIN_DIR/sway_spaces.sh; check_current_active_space_label)
    active_space_label=$(echo "$full_label" | /usr/bin/sed 's/[^0-9]*//g')  # Remove all non-numeric characters

    relevant_spaces=($($PLUGIN_DIR/print_spaces_sketchybar.sh | tr ' ' '\n' | /usr/bin/sed 's/^_//'))
    relevant_spaces=($(echo "${relevant_spaces[@]}" | tr ' ' '\n' | sort -n))  # Sort spaces numerically

    sketchybar_spaces=($(sketchybar --query bar | jq -r '.items[] | select(startswith("space."))'))

    for space in "${relevant_spaces[@]}"; do
        label=$(echo "$space" | /usr/bin/sed 's/^_//')  # Ensure no leading underscore
        color="$WHITE"  # Default color
        [[ "$label" == "$active_space_label" ]] && color="$ORANGE"  # Set color to ORANGE if it's the active space

        if [[ ! " ${sketchybar_spaces[*]} " =~ " space.$label " ]]; then
            sketchybar --add item space.$label left
        fi

        sketchybar --set space.$label \
                        label="$label" \
                        label.color="$color" \
                        click_script="yabai -m space --focus $active_space_label" \
                        padding_left=5 \
                        padding_right=5 \
                        drawing=on
        sketchybar_spaces=("${sketchybar_spaces[@]/space.$label/}")
    done

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

    # echo -e "\nrelevent spaces: \n$relevant_spaces"

   echo $active_space_label
    # check_current_active_display
    # check_current_active_display_label

    # check_current_active_space
    # check_current_active_space_label
}

echo -e "\n\n\nRunning update_sketchybar_spaces\n\n\n"
update_sketchybar_spaces
