#!/bin/bash

# Function to disable gaps, sketchybar, menubar, and enable Zoom fullscreen
enable_fullscreen() {
  toggle-gaps off
  toggle-sketchybar off
  toggle-menubar off
  toggle-dock off
  yabai -m window --toggle zoom-fullscreen
}

# Function to enable gaps, sketchybar, menubar, and disable Zoom fullscreen
disable_fullscreen() {
  # toggle-gaps "$gaps_restore_state"
  # toggle-sketchybar "$sketchybar_restore_state"
  # toggle-menubar "$menubar_restore_state"
  # toggle-dock "$dock_restore_state"
  toggle-gaps "on"
  toggle-sketchybar "on"
  toggle-menubar "on"
  # toggle-dock "on"
  yabai -m window --toggle zoom-fullscreen
}


# Function to check if the focused window is in Zoom fullscreen mode and toggle it
toggle_fullscreen() {
  # Get information about the currently focused window
  window_info=$(yabai -m query --windows --window | jq -r '.["has-fullscreen-zoom"]')

  # Output the state of Zoom fullscreen mode
  if [ "$window_info" == "false" ]; then
    echo "Zoom fullscreen mode is disabled. enabling..."
    
    # Define the paths to the state files
    gaps_state_file="/tmp/gaps_state"
    sketchybar_state_file="/tmp/sketchybar_state"
    menubar_state_file="/tmp/menubar_state"
    dock_state_file="/tmp/dock_state"

    # Read the current states from the state files
    gaps_restore_state=$(cat "$gaps_state_file" 2>/dev/null)
    sketchybar_restore_state=$(cat "$sketchybar_state_file" 2>/dev/null)
    menubar_restore_state=$(cat "$menubar_state_file" 2>/dev/null)
    dock_restore_state=$(cat "$dock_state_file" 2>/dev/null)

    enable_fullscreen
  else
    echo "Zoom fullscreen mode is enabled. disabling..."
    disable_fullscreen
  fi
}

# Call the toggle_fullscreen function
toggle_fullscreen
