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

#FIXME: show second page.
sketchybar --add item apple.uname popup.apple \
  --set apple.uname label="$(uname -s -r -m)" \
    label.padding_left=10 \
    label.padding_right=10 \
--add item apple.sw_vers popup.sw_vers \ 
  --set apple.sw_vers label="$(sw_vers | awk '/ProductName/ {printf $2" "} /ProductVersion/ {printf $2" "} /BuildVersion/ {print "(" $2")"}')" \
    label.padding_left=10 \
    label.padding_right=10

    #icon=$APPLE "${properties[@]}" ]

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sleep 2  # Wait for 2 seconds before showing the popup
      sketchybar --set $NAME popup.drawing=on
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    ;;
  "mouse.clicked")
    sketchybar --set $NAME popup.drawing=toggle
    ;;
  "routine")
    ;;
esac
