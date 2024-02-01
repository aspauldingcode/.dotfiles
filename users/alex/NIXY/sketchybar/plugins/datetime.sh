#!/bin/bash

source "$HOME/.config/sketchybar/items/calendar.sh"

# Function to set date and time
function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d  %I:%M %p')"
  sketchybar --set $NAME icon=$TIME
}

set_date_and_time # call it first


# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME popup.drawing=on
    #echo "Mouse Hovered in $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    #echo "Mouse left hover of $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.clicked")
    sketchybar --set $NAME popup.drawing=toggle
    #echo "Mouse clicked on $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "routine")
    # Update date_and_time periodically
    set_date_and_time
    ;;
esac
