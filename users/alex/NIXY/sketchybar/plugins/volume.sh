#!/bin/sh
#FIXME: Add bluetooth headphone indicator with Battery:https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1549450
source "$HOME/.config/sketchybar/icons.sh"

volume_change() {
  case $INFO in
  [6-9][0-9] | 100)
    ICON=$VOLUME
    ;;
  [3-5][0-9])
    ICON=$VOLUME_66
    ;;
  [1-2][0-9])
    ICON=$VOLUME_33
    ;;
  [1-9])
    ICON=$VOLUME_10
    ;;
  0)
    ICON=$VOLUME_0
    ;;
  *) ICON=$VOLUME_100 ;;
  esac

  sketchybar --set volume label="$ICON $INFO%" #add the icon and the percentage
}

#volume_change # Run it once to set the icon and label!

case "$SENDER" in
"volume_change")
  volume_change
  ;;
"mouse.scrolled")
  # Extract the delta value from INFO (assuming it's in JSON format)
  SCROLL_DELTA=$(echo "$INFO" | tr -d '{}' | awk -F':' '/delta/ {print $2}' | tr -d ' ')

  # Get the current volume level
  CURRENT_VOLUME=$(osascript -e "output volume of (get volume settings)")

  # Calculate the new volume level
  NEW_VOLUME=$((CURRENT_VOLUME + SCROLL_DELTA * 2))

  # Ensure the volume doesn't go below 0 or above 100
  NEW_VOLUME=$(awk -v v="$NEW_VOLUME" 'BEGIN {print (v < 0) ? 0 : (v > 100) ? 100 : v}')

  # Adjust volume using osascript
  osascript -e "set volume output volume $NEW_VOLUME"
  ;;
  "routine")
    ;;
esac

