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

sketchybar --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="$(system_profiler SPAudioDataType -xml | awk -F'<|>' '/<dict>/ {output_name=""; default_output=0} /<key>_name<\/key>/{getline; output_name=$3} /<key>coreaudio_default_audio_output_device<\/key>/{default_output=1} /<\/dict>/ && default_output {print output_name; exit}')" \
  label.padding_left=10 \
  label.padding_right=10 \

# Handle mouse events
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
    open /System/Library/PreferencePanes/Sound.prefPane
    #sketchybar --set $NAME popup.drawing=toggle
    #echo "Mouse clicked on $NAME icon" >> /tmp/sketchybar_debug.log
    # toggle_battery_popup
    ;;
  "routine")
    # Update battery info periodically
    #update_battery
    ;;
esac

