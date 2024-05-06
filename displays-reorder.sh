#!/bin/bash

# Function to reorder displays
reorder_displays() {
    local auto_flag="$1"

    # Function to prompt user for display label
    prompt_for_label() {
        local display_index="$1"
        local assigned_labels=("${!2}")
        
        # Get the count of displays
        local displays_count
        displays_count=$(yabai -m query --displays | jq length)

        # Generate list of display labels
        local display_labels=()
        for ((i = 1; i <= displays_count; i++)); do
            display_labels+=("$i")
        done

        # Display a dialog box for user input
        label_index=$(osascript -e "tell application \"Finder\" to choose from list {\"${display_labels[@]}\"} with prompt \"Select the label for display $display_index:\" default items {\"1\"}" | tr -d '[:space:]')

        # Check if input is empty
        if [ -z "$label_index" ]; then
            echo "Error: Label cannot be empty. Please try again."
            prompt_for_label "$display_index" assigned_labels[@]
            return
        fi

        # Check if label is unique
        local label="_$label_index"
        if [[ " ${assigned_labels[@]} " =~ " $label " ]]; then
            echo "Error: Label $label is already assigned to another display. Please choose a different label."
            prompt_for_label "$display_index" assigned_labels[@]
            return
        else
            echo "Setting label '$label' for display $display_index..."
            # Set the label for the display
            echo "$display_index: $label" >> "$HOME/.config/yabai/display_order"
            yabai -m display "$display_index" --label "$label"
            assigned_labels+=("$label") # Add assigned label to the list
            return
        fi
    }

    # Function to handle moving the prompt to the next display
    move_prompt_to_next_display() {
        # Get the current display index
        current_display_index=$(yabai -m query --displays --display | jq -r '.index')
        
        # Get the total number of displays
        total_displays=$(yabai -m query --displays | jq length)

        # Calculate the next display index
        next_display_index=$((current_display_index % total_displays + 1))
        
        # Move the prompt to the next display
        yabai -m window --display "$next_display_index"
    }

    # Function to handle display labeling and ordering
    handle_displays() {
        local assigned_labels=()

        # Reset display order file if not running with --auto flag
        if [ "$auto_flag" != "--auto" ]; then
            echo "Resetting display order file..."
            > "$HOME/.config/yabai/display_order"
        fi

        # Main script logic
        if [ "$auto_flag" == "--auto" ]; then
            # Check if the display order file exists and is non-empty
            if [ -s "$HOME/.config/yabai/display_order" ]; then
                # Read settings from input file and apply them using yabai
                local input_file="$HOME/.config/yabai/display_order"
                local lines=$(wc -l < "$input_file")
                local displays_count=$(yabai -m query --displays | jq length)

                if [ "$lines" -eq "$displays_count" ]; then
                    echo "Reading settings from $input_file and applying..."
                    while IFS= read -r line; do
                        local display_index=$(echo "$line" | cut -d':' -f1)
                        local label=$(echo "$line" | cut -d':' -f2 | sed 's/ //g')
                        echo "Setting label '$label' for display $display_index..."
                        yabai -m display "$display_index" --label "$label"
                        assigned_labels+=("$label") # Add assigned label to the list
                    done < "$input_file"
                    return  # Exit function if --auto flag is provided and settings are loaded
                else
                    echo "Number of lines in $input_file does not match the number of displays."
                    echo "Resetting display order file..."
                    > "$HOME/.config/yabai/display_order"
                fi
            else
                echo "Display order file is empty or doesn't exist."
                echo "Launching interactive mode..."
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
                assigned_labels+=("_1") # Add assigned label to the list
            fi
        else
            # Prompt user for labels and reorder displays
            local display_index=1
            while [ $display_index -le $displays_count ]; do
                prompt_for_label $display_index assigned_labels[@]
                ((display_index++))
            done
        fi

        # Move the prompt to the next display
        move_prompt_to_next_display
    }

    # Function to confirm display orders
    confirm_display_orders() {
        if [ "$auto_flag" != "--auto" ]; then
            echo "Just to confirm. You've set:"
            echo "Display: _Label"
            cat "$HOME/.config/yabai/display_order"
            confirm_choice=$(osascript -e "display dialog \"Display: _Label\n$(cat $HOME/.config/yabai/display_order)\nDoes this look correct?\" buttons {\"Enter\", \"Reset\"} default button \"Enter\"" | tr -d '[:space:]')
            case "$confirm_choice" in
                Enter)
                    ;;
                Reset)
                    echo "Resetting display orders..."
                    rm "$HOME/.config/yabai/display_order"
                    exit
                    ;;
                *)
                    echo "Exiting..."
                    exit 1
                    ;;
            esac
        fi
    }

    # Call function to handle display labeling and ordering
    handle_displays "$auto_flag"
    confirm_display_orders
}

# Call the function with provided arguments
reorder_displays "$@"
