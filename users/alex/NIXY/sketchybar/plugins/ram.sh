#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch.sh"

RAM=$(vm_stat | awk '/Pages free:/ {free=$3} /Pages active:/ {active=$3} /Pages inactive:/ {inactive=$3} /Pages speculative:/ {speculative=$3} END {total=free + active + inactive + speculative; used=active + inactive; print int(100*used/total)}')

sketchybar --set $NAME label="$RAM%"

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
