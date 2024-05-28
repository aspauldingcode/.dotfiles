#!/bin/bash

while true; do
    # Call print_spaces.sh from its location and store the output
    relevant_spaces=($(bash ~/.dotfiles/CUSTOM_yabai_scripts/print_spaces.sh))

    # Retrieve the label of the active space from yabai
    active_space=$(yabai -m query --spaces --space | jq -r '.label' | sed 's/^_//')

    # Retrieve current spaces from SketchyBar before the loop
    sketchybar_spaces=$(sketchybar --query bar | jq -r '.items[] | select(startswith("space."))')

    # Loop through each relevant space and add or update an item in SketchyBar
    for space in "${relevant_spaces[@]}"; do
        # Trim leading underscore from the label
        label=$(echo "$space" | sed 's/^_//')

        # Determine color based on active space
        color="0xff95A5A6"  # Gray for inactive spaces
        background_color="0x5595A5A6"  # Slightly transparent gray
        if [[ "$label" == "$active_space" ]]; then
            color="0xffF1C40F"  # Yellow for active space
            background_color="0x55F1C40F"  # Slightly transparent yellow
        fi

        # Command to add or update a space item to SketchyBar with color, background, and spacing
        sketchybar --add item space.$label left \
                   --set space.$label \
                        label="$label" \
                        background.color="$background_color" \
                        label.color="$color" \
                        click_script="yabai -m space --focus _$label" \
                        padding_left=10 \
                        padding_right=10 \
                        drawing=on

        # Remove label from sketchybar_spaces to track which spaces are still active
        sketchybar_spaces=$(echo "$sketchybar_spaces" | grep -v "space.$label")
    done

    # Remove any space items from SketchyBar that no longer exist
    for space_id in $sketchybar_spaces; do
        sketchybar --remove $space_id
    done

    # Sort and reorder should be done after all removals
    sketchybar_spaces=$(sketchybar --query bar | jq -r '.items[] | select(startswith("space."))')
    sorted_spaces=($(echo "$sketchybar_spaces" | sort -t '_' -k 2n))
    sketchybar --reorder ${sorted_spaces[@]}

    source $HOME/.dotfiles/users/alex/NIXY/sketchybar/plugins/sway_spaces.sh

    sleep 3
done
