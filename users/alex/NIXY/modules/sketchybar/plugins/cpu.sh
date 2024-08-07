#!/bin/sh

CPU=$(top -l 1 | awk '/^CPU usage:/ {print $3}' | tr -d '%' | cut -d "." -f1)

sketchybar --set $NAME label="$CPU%"

sketchybar --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="$(uname -s -r -m)" \
    label.padding_left=10 \
    label.padding_right=10 \

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
    #update_battery
    ;;
esac
