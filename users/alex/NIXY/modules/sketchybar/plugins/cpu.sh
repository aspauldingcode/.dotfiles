#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
# source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

CPU=$(top -l 1 | awk '/^CPU usage:/ {print $3}' | tr -d '%' | cut -d "." -f1)

sketchybar --set $NAME label="$CPU%" icon=$CPU_ICON

sketchybar --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="$(uname -s -r -m)" \
    label.padding_left=10 \
    label.padding_right=10 \

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
    #update_battery
    ;;
esac
