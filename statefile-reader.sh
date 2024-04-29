gaps_state_file="/tmp/gaps_state"
sketchybar_state_file="/tmp/sketchybar_state"
dock_state_file="/tmp/dock_state"
menubar_state_file="/tmp/menubar_state"
darkmode_state_file="/tmp/darkmode_state"

# Function to read state from file
read_state() {
    if [ -f "$1" ]; then
        cat "$1"
    else
        echo "off"
    fi
}

# Read the current state from the state files, if they exist
gaps_state=$(read_state "$gaps_state_file")
sketchybar_state=$(read_state "$sketchybar_state_file")
dock_state=$(read_state "$dock_state_file")
menubar_state=$(read_state "$menubar_state_file")
darkmode_state=$(read_state "$darkmode_state_file")

# Function to check dark mode status and update darkmode state file
check_darkmode_status() {
    darkmode_status=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
    if [ "$darkmode_status" = "true" ]; then
        darkmode_state="on"
    else
        darkmode_state="off"
    fi
    echo "$darkmode_state" > "$darkmode_state_file"
}

# Call the function to check dark mode status
check_darkmode_status

# Update the sketchybar state
sketchybar_hidden_status=$(sketchybar --query bar | jq -r '.hidden')
if [ "$sketchybar_hidden_status" = "on" ]; then
    sketchybar_state="off"
elif [ "$sketchybar_hidden_status" = "off" ]; then 
    sketchybar_state="on"
fi

# Update the dock state
dock_status=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')
if [ "$dock_status" = "true" ]; then
    dock_state="off"
elif [ "$dock_status" = "false" ]; then
    dock_state="on"
fi

echo "Gaps is: $gaps_state"
echo "Sketchybar is: $sketchybar_state"
echo "Dock is: $dock_state"
echo "Menubar is: $menubar_state"
echo "Dark Mode is: $darkmode_state"
