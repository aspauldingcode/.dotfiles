#!/bin/bash

# Function to create a new space label and assign it to an empty space
assign_new_label() {
    local index=$1
    local label="_$index"
    yabai -m space "$index" --label "$label"
    echo "Assigned label $label to space $index"
}

# Function to label spaces
label_spaces() {
    local num_spaces=$(yabai -m query --spaces | jq length)
    for ((i = 1; i <= num_spaces; i++)); do
        yabai -m space "$i" --label "_$i"
    done
    echo "Spaces labeled successfully."
}

# Function to read space number
read_space_number() {
    local space_label=$(yabai -m query --spaces --space | jq -r '.label')
    if [ -n "$space_label" ]; then
        local space_number=$(echo "$space_label" | cut -d'_' -f2)
        if [ -n "$space_number" ]; then
            echo "Currently on space: $space_number"
        else
            echo "Error: Could not extract space number from label."
        fi
    else
        echo "Error: Could not retrieve space label."
    fi
}

# Function to label displays
label_displays() {
    local num_displays=$(yabai -m query --displays | jq length)
    for ((i = 1; i <= num_displays; i++)); do
        yabai -m display "$i" --label "_$i"
    done
    echo "Displays labeled successfully."
}

# Function to read display number
read_display_number() {
    local display_label=$(yabai -m query --displays --display | jq -r '.label')
    if [ -n "$display_label" ]; then
        local display_number=$(echo "$display_label" | cut -d'_' -f2)
        if [ -n "$display_number" ]; then
            echo "Currently on display: $display_number"
        else
            echo "Error: Could not extract display number from label."
        fi
    else
        echo "Error: Could not retrieve display label."
    fi
}

# Function to read all spaces in label order
read_all_spaces() {
    echo "All spaces information:"
    for index in $(yabai -m query --spaces | jq -r '.[].index'); do
        label=$(get_space_label "$index")
        windows=$(yabai -m query --spaces --space "$index" | jq -r '.windows | length')
        if [ "$windows" -gt 0 ]; then
            windows_indicator="W"
        else
            windows_indicator=""
        fi
        echo "$index: $label $windows_indicator"
    done | sort -t ':' -k 2 -n -t '_' -k 2
}

# Function to read all displays
read_all_displays() {
    echo "All Displays:"
    yabai -m query --displays | jq -r '.[] | "\(.index): \(.label) \(if .["has-focus"] == true then "A" else "" end)"'
}

# Function to read all labels
read_all_labels() {
    local all_labels=$(yabai -m query --spaces | jq -r '.[].label' | sort -t '_' -k 2 -n)
    echo "All Labels:"
    echo "$all_labels"
}

# Function to read spaces on display n for all displays
read_spaces_on_display_n_for_all_displays() {
    num_displays=$(yabai -m query --displays | jq length)
    for ((i=1; i<=$num_displays; i++)); do
        display_active=$(yabai -m query --displays --display $i | jq -r '.["has-focus"]')
        if [ "$display_active" = "true" ]; then
            active_flag=": A"
        else
            active_flag=""
        fi
        echo "Display $i$active_flag:"
        local all_spaces=$(yabai -m query --spaces --display $i | jq -r '.[] | "\(.index): \(.label) \(.windows | length > 0 | if . then "W" else "" end)"')
        echo "$all_spaces" | sort -t ':' -k 2 -n -t '_' -k 2
    done
}

# Function to read spaces for current display
read_spaces_for_current_display() {
    current_display=$(yabai -m query --displays --display | jq -r '.index')
    echo "Spaces for Display $current_display:"
    yabai -m query --spaces --display | jq -r '.[] | "\(.index): \(.label)"'
}

# Function to get label of space n
get_space_label() {
    local space_index="$1"
    local space_label=$(yabai -m query --spaces --space "$space_index" | jq -r '.label')
    if [ -z "$space_label" ]; then
        space_label="EL"
    fi
    echo "$space_label"
}

# Function to return indices of spaces missing labels
missing_label_spaces() {
    missing_spaces=()
    for index in $(yabai -m query --spaces | jq -r '.[].index'); do
        label=$(get_space_label "$index")
        if [ "$label" = "EL" ]; then
            missing_spaces+=("$index")
        fi
    done
    echo "${missing_spaces[@]}"
}

generate_unique_labels() {
    # Get indexes of spaces with missing labels
    missing_indexes=$(missing_label_spaces)
    
    # Check if there are any missing indexes
    if [ -z "$missing_indexes" ]; then
        echo "No missing space labels found."
        return
    fi
    
    # Sort the missing indexes numerically
    sorted_indexes=$(echo "$missing_indexes" | tr ' ' '\n' | sort -n)
    
    # Initialize an array to keep track of assigned labels
    declare -A assigned_labels
    
    # Get all existing space labels
    all_labels=$(yabai -m query --spaces | jq -r '.[] | select(.label != null) | .label')

    # Loop through existing labels and mark them as assigned
    for label in $all_labels; do
        label_index=$(echo "$label" | cut -d'_' -f2)
        assigned_labels["$label_index"]=1
    done

    # Iterate over missing indexes and assign unique labels
    for index in $sorted_indexes; do
        # Find the next available label
        label=""
        for ((i=1; ; i++)); do
            if [ -z "${assigned_labels[$i]}" ]; then
                label="_$i"
                assigned_labels["$i"]=1
                break
            fi
        done

        # Assign the label to the missing space
        yabai -m space "$index" --label "$label"
        echo "Assigned label '$label' to space $index"
    done
    echo "Unique labels generated for missing space labels."
}

# Function to print space labels
print_space_labels() {
    # Query for spaces with windows
    spaces_with_windows=($(yabai -m query --spaces | jq -r '.[] | select(.windows | length > 0) | .label'))

    # Query for the active space
    active_space=$(yabai -m query --spaces --space | jq -r '.label')

    # active space per display
    # Query for the total number of displays
    total_displays=$(yabai -m query --displays | jq 'length')

    # Initialize an array to store active display spaces
    active_display_spaces=()

    # Loop through each display
    for ((display=1; display<=$total_displays; display++)); do
        # Query for spaces on the current display that are visible
        spaces=$(yabai -m query --spaces --display $display | jq -r '.[] | select(.["is-visible"] == true) | .label')

        # Add visible spaces to the active_display_spaces array
        for space in $spaces; do
            active_display_spaces+=("$space")
        done
    done

    # Combine spaces with windows and active spaces on all displays
    print=($(echo "${spaces_with_windows[@]}" "${active_display_spaces[@]}" | tr ' ' '\n' | sort -u))

    # Print the formatted output
    echo "Space Labels with Windows or Active on Display(s):"
    for space_label in "${print[@]}"; do
        echo "$space_label"
    done
}

# Function to remove unimportant spaces
remove_unimportant_spaces() {
    # Get the list of important space labels
    important_spaces=($(print_space_labels))

    # Get the list of all space labels
    all_spaces=($(yabai -m query --spaces | jq -r '.[] | .label'))

    # Remove unimportant spaces
    for space_label in "${all_spaces[@]}"; do
        if ! [[ " ${important_spaces[@]} " =~ " $space_label " ]]; then
            yabai -m space "$space_label" --destroy
            echo "Removed unimportant space: $space_label"
        fi
    done
}

generate_new_space() {
    local new_label="$1"

    # Generate unique labels for missing spaces
    generate_unique_labels

    # Create a new space
    yabai -m space --create

    # Rename the newly created space with the specified label
    yabai -m space --label "$new_label"
}



#!/bin/bash

# Function to reorder displays
reorder_displays() {
    local auto_flag="$1"

    # Function to prompt user for display label
    prompt_for_label() {
        local display_index="$1"
        echo "Prompting for label on display $display_index..."
        yabai -m window --display "$display_index"
        yabai -m display --focus "$display_index"
        yabai -m window --grid 60:60:5:5:50:50; borders order=above

        # Get the count of displays
        local displays_count
        displays_count=$(yabai -m query --displays | jq length)
        
        # Loop until valid integer input within the range is provided
        while true; do
            echo "Which display is this? (Enter a number between 1 and $displays_count)"
            read -p "Display $display_index: " label_index
            
            # Check if input is an integer and within the range
            if [[ $label_index =~ ^[1-$displays_count]$ ]]; then
                if grep -q "^$display_index: _" "$HOME/.config/yabai/display_order"; then
                    echo "Warning: Label for display $display_index already set. Skipping..."
                else
                    echo "Setting label '_$label_index' for display $display_index..."
                    # Set the label for the display
                    local label="_$label_index"
                    echo "$display_index: $label" >> "$HOME/.config/yabai/display_order"
                    yabai -m display "$display_index" --label "$label"
                fi
                break
            else
                echo "Error: Please enter a valid integer between 1 and $displays_count."
            fi
        done
    }

    # Function to handle display labeling and ordering
    handle_displays() {
        # Main script logic
        if [ "$auto_flag" == "--auto" ]; then
            # Check if the display order file exists and is non-empty
            if [ -s "$HOME/.config/yabai/display_order" ]; then
                # Read settings from input file and apply them using yabai
                local input_file="$HOME/.config/yabai/display_order"
                echo "Reading settings from $input_file and applying..."
                while IFS= read -r line; do
                    local display_index=$(echo "$line" | cut -d':' -f1)
                    local label=$(echo "$line" | cut -d':' -f2 | sed 's/ //g')
                    echo "Setting label '$label' for display $display_index..."
                    yabai -m display "$display_index" --label "$label"
                done < "$input_file"
            else
                echo "Display order file is empty or doesn't exist. Running default logic."
                auto_flag=""
            fi
        fi

        # Check the number of displays
        local displays_count
        displays_count=$(yabai -m query --displays | jq length)
        
        # If there's only one display, immediately set label _1
        if [ "$displays_count" -eq 1 ]; then
            if ! grep -q "^1: _" "$HOME/.config/yabai/display_order"; then
                echo "Setting label '_1' for the only display..."
                echo "1: _1" > "$HOME/.config/yabai/display_order"
                yabai -m display 1 --label "_1"
            fi
        else
            # Launch Alacritty in a new terminal window
            echo "Launching Alacritty in a new terminal window..."
            /opt/homebrew/bin/alacritty -e bash -c "
                > $HOME/.config/yabai/display_order # Clear the file
                local display_index=1
                while [ \$display_index -le $displays_count ]; do
                    prompt_for_label \$display_index
                    ((display_index++))
                done
            "
        fi
    }

    # Call function to handle display labeling and ordering
    handle_displays "$auto_flag"
}

# Function to display menu and run selected function
display_menu() {
    echo "Choose an option:"
    echo "1. Label Spaces"
    echo "2. Read Space Number"
    echo "3. Read All Spaces"
    echo "4. Label Displays"
    echo "5. Read Display Number"
    echo "6. Read All Displays"
    echo "7. Read All Labels"
    echo "8. Generate unique labels to missing space labels"
    echo "9. Read Spaces on Display n for All Displays"
    echo "10. Read Spaces for Current Display"
    echo "11. Check for Missing Space Labels"
    echo "12. Exit"

    read -p "Enter option number: " choice

    case $choice in
        1) label_spaces ;;
        2) read_space_number ;;
        3) read_all_spaces ;;
        4) label_displays ;;
        5) read_display_number ;;
        6) read_all_displays ;;
        7) read_all_labels ;;
        8) generate_unique_labels ;;
        9) read_spaces_on_display_n_for_all_displays ;;
        10) read_spaces_for_current_display ;;
        11) missing_label_spaces ;;
        12) exit ;;
        *) echo "Invalid option. Please choose a valid option." ;;
    esac
}


# Main function
main() {
    while true; do
        display_menu
    done
}

# Run the main function if the script is executed directly
if [ "$(basename "$0")" = "$(basename "$BASH_SOURCE")" ]; then
    main
fi
