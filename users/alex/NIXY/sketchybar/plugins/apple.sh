#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

#POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
#POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

properties=(
  label.y_offset=0
  label.padding_left=4
  label.padding_right=10
  #label.font="DejaVu Mono:Bold:12.0"
  #icon.font="DejaVu Mono:Regular:14.0"
  icon.padding_left=10
  #height=10
  #background.margin=25
  #blur_radius=100
  width=175
)

sketchybar --add item apple.popup popup.apple \
  --set apple.popup label="$(uname -s -r -m)" \
    icon=$APPLE "${properties[@]}" 

  # Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sleep 1
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
