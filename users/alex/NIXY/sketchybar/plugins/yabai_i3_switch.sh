#!/bin/bash

echo -e "\n\nRUNNING yabai-i3-switch.sh NOW!!!"

# Path to the fullscreen state file
fullscreen_state_file="/tmp/fullscreen_state"

# Get the name of the frontmost application
front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
echo "Frontmost application is: $front_app"

# Use sketchybar to get the focused window ID
window_id=$(/opt/homebrew/bin/yabai -m query --windows --window | jq -r '."id"')

# Check if the window ID is in fullscreen mode
is_fullscreen=$(/usr/bin/grep "id: $window_id fullscreen:" "$fullscreen_state_file" | /usr/bin/tail -1 | awk '{print $NF}')

echo "$window_id"
echo "$is_fullscreen"

# Function to update or append the fullscreen state
function update_state_file() {
    if /usr/bin/grep -q "id: $window_id fullscreen:" "$fullscreen_state_file"; then
        # Window ID exists, update the line
        if [[ "$is_fullscreen" != "on" && "$is_fullscreen" != "off" ]]; then
            is_fullscreen="off"
        fi
        /usr/bin/sed -i '' "s/id: $window_id fullscreen:.*/id: $window_id fullscreen: $is_fullscreen/" "$fullscreen_state_file"
    else
        # Window ID does not exist, append the line with default state 'off'
        echo "id: $window_id fullscreen: off" >> "$fullscreen_state_file"
    fi
}

# Call the function to update the state file
update_state_file

# Check if the frontmost application is X11.bin
if [ "$front_app" = "X11.bin" ]; then
    echo "Setting mouse modifier to fn"
    /opt/homebrew/bin/yabai -m config mouse_modifier fn
else
    echo "Setting mouse modifier to alt"
    /opt/homebrew/bin/yabai -m config mouse_modifier alt
fi

# Check if the current window is fullscreen
if [ "$is_fullscreen" = "on" ]; then
    /opt/homebrew/bin/yabai -m config mouse_modifier fn # turns off yabai mouse shortcut
    update_state_file
    toggle-dock off
else
    # If the window is not fullscreen, handle the non-fullscreen case
    /opt/homebrew/bin/yabai -m config mouse_modifier alt # enables alt modifier for yabai again
    update_state_file
fi
