#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

batt() {
  if [ "$PERCENTAGE" = "" ]; then  # Use double quotes for variable comparison
    exit 0
  fi

  case ${PERCENTAGE} in
    9[0-9] | 100)
      ICON="$BATTERY"
      ;;
    [6-8][0-9])
      ICON="$BATTERY_75"
      ;;
    [3-5][0-9])
      ICON="$BATTERY_50"
      ;;
    [1-2][0-9])
      ICON="$BATTERY_25"
      ;;
    *) ICON="$BATTERY_0" ;;
  esac

  if [[ "$CHARGING" != "" ]]; then  # Use double quotes for variable comparison
    ICON="$BATTERY_LOADING"
  fi

  # Use a single update command at the end to avoid multiple calls
  sketchybar --set $NAME icon="$ICON"
}

# Function to update battery icon and popup
update_battery() {
  batt

  # Define battery popup properties
  battery_popup=(
    $NAME.popup label="$PERCENTAGE%"
    icon="$ICON" 
    icon.padding_left=10
    label.padding_left=8
    label.padding_right=10
    height=10
    blur_radius=100
  )

  # Use a single update command at the end to avoid multiple calls
  sketchybar --add item $NAME.popup popup.$NAME --set "${battery_popup[@]}"
}

# Check if battery information is available
if pmset -g batt | grep -q "Battery"; then
  update_battery
else
  # Remove the battery item if no battery is found
  sketchybar --remove battery
  exit 0
fi

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME popup.drawing=on
    
    # highlight effect
    sketchybar --set $NAME icon.highlight=on label.highlight=on icon.highlight_color=$base07 label.highlight_color=$base07
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off

    # unhighlight effect
    sketchybar --set $NAME icon.highlight=off label.highlight=off
    ;;
  "mouse.clicked")
    # button clicked effect
    sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    # Update battery info periodically
    update_battery
    ;;
esac
