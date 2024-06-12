#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch.sh"

brightness_change() {
  case $INFO in
  [8-9][0-9] | 100)
    ICON=$BACKLIGHT_7
    ;;
  [6-7][0-9])
    ICON=$BACKLIGHT_6
    ;;
  [4-5][0-9])
    ICON=$BACKLIGHT_6
    ;;
  [0-3][0-9])
    ICON=$BACKLIGHT_4
    ;;
  *)
    ICON=$BACKLIGHT_5
    ;;
  esac

  sketchybar --set backlight label="$ICON $INFO%" # add the icon and the percentage
}

sketchybar --add item backlight.popup popup.backlight \
  --set backlight.popup label="$(system_profiler SPDisplaysDataType -xml | awk -F'<|>' '/<key>spdisplays_brightness<\/key>/{getline; print $3}' | awk '{printf "%.0f", $1*100}')" \
  label.padding_left=10 \
  label.padding_right=10 \

# Handle mouse events
case "$SENDER" in
"brightness_change")
  brightness_change
  ;;
"mouse.scrolled")
  # Extract the delta value from INFO (assuming it's in JSON format)
  SCROLL_DELTA=$(echo "$INFO" | tr -d '{}' | awk -F':' '/delta/ {print $2}' | tr -d ' ')

  # Get the current brightness level
  CURRENT_BRIGHTNESS=$(brightness -l | grep brightness | awk '{print $4 * 100}')

  # Calculate the new brightness level
  NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS + SCROLL_DELTA * 2))

  # Ensure the brightness doesn't go below 0 or above 100
  NEW_BRIGHTNESS=$(awk -v v="$NEW_BRIGHTNESS" 'BEGIN {print (v < 0) ? 0 : (v > 100) ? 100 : v}')

  # Adjust brightness using brightness command
  brightness -l | grep display | awk '{print $2}' | while read -r display; do
    brightness -d $display -v $(awk -v v="$NEW_BRIGHTNESS" 'BEGIN {print v / 100}')
  done
  ;;
"mouse.entered")
  sketchybar --set backlight popup.drawing=on
  ;;
"mouse.exited" | "mouse.exited.global")
  sketchybar --set backlight popup.drawing=off
  ;;
"mouse.clicked")
  open /System/Library/PreferencePanes/Displays.prefPane
  ;;
"routine")
  # Update brightness info periodically
  ;;
esac
