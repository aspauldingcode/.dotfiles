#!/bin/bash

# Function to prompt the user for the display identification
prompt_for_display() {
    local script="try
                    tell application \"System Events\"
                        set user_input to text returned of (display dialog \"What display is this?\" default answer \"\" buttons {\"OK\"} default button 1 with title \"Display Identification\" giving up after 60)
                    end tell
                    if user_input is not \"\" then
                        return user_input
                    else
                        error \"User cancelled the dialog\"
                    end if
                  on error error_message number error_number
                    return \"Error: \" & error_message & \" (Number \" & error_number & \")\"
                  end try"

    # Execute the AppleScript and capture the output
    display_id=$(osascript -e "$script")

    # Check for errors
    if [[ "$display_id" == Error:* ]]; then
        echo "An error occurred: $display_id"
        return 1
    fi

    echo "Display ID entered: $display_id"
}

# Call the function
prompt_for_display