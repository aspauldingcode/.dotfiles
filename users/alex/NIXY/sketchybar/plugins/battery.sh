#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

batt() {
  if [ $PERCENTAGE = "" ]; then
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

  if [[ $CHARGING != "" ]]; then
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
    icon="$ICON"
    label="$PERCENTAGE %"
    label.y_offset=0
    label.font="DejaVu Mono:Bold:12.0"
    height=10
    blur_radius=100
  )

  # Use a single update command for the popup
  sketchybar --set $NAME.popup "${battery_popup[@]}"
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
    #sleep 1
    sketchybar --set $NAME popup.drawing=on
    #echo "Mouse Hovered in $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    #echo "Mouse left hover of $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.clicked")
    #sketchybar --set $NAME popup.drawing=toggle
    #echo "Mouse clicked on $NAME icon" >> /tmp/sketchybar_debug.log
    # toggle_battery_popup
    ;;
  "routine")
    # Update battery info periodically
    update_battery
    ;;
esac
