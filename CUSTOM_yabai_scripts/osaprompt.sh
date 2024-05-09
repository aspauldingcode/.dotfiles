#!/bin/bash

# Function to prompt the user for a yes/no response using osascript
prompt_yes_no() {
    response=$(osascript -e "display dialog \"$1\" buttons {\"No\", \"Yes\"} default button \"Yes\"")
    button_pressed=$(echo "$response" | awk -F 'button returned:' '{print $2}' | tr -d '[:space:]')
    echo "$button_pressed"
}

# Prompt the user for confirmation
user_response=$(prompt_yes_no "Do you want to continue?")

# Check the user's response
if [ "$user_response" == "Yes" ]; then
    echo "You selected 'Yes'"
    # Run the script if user selected 'Yes'
    bash ~/.dotfiles/displays-reorder.sh
else
    echo "You selected 'No'"
fi
