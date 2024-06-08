#!/bin/bash

# Function to prompt the user for the display identification using Python
prompt_for_display() {
    # Call the Python script and capture the output
    display_id=$(python3 prompt_display.py)

    # Check if input is empty
    if [ -z "$display_id" ]; then
        echo "No display ID entered or dialog was closed."
        return 1
    fi

    echo "Display ID entered: $display_id"
}

# Call the function
prompt_for_display