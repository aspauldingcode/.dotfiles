# Locks a windowed-fullscreen window in its place, so it doesn't move. 
# Fixes any bugs with custom functions.
#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch.sh"

# Path to the fullscreen state file
fullscreen_state_file="/tmp/fullscreen_state"

# Get the name of the frontmost application
front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
# Use yabai to get the focused window ID
window_id=$(/opt/homebrew/bin/yabai -m query --windows --window | jq -r '."id"')
# Check if the window ID is in fullscreen mode
is_fullscreen=$(/usr/bin/grep "id: $window_id fullscreen:" "$fullscreen_state_file" | /usr/bin/tail -1 | awk '{print $NF}')

# Function to check and correct the current window's frame status
check_current_window() {
    local current_window_frame=$(/opt/homebrew/bin/yabai -m query --windows --window | jq '.frame')
    local expected_window_frame=$(/opt/homebrew/bin/yabai -m query --displays --display | jq '.frame')
    if [ "$current_window_frame" != "$expected_window_frame" ]; then
        toggle-instant-fullscreen on
    fi
}

# Check if the current window is fullscreen and call the function if true
if [ "$is_fullscreen" = "on" ]; then
    check_current_window
fi
