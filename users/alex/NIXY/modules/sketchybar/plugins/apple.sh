#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

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
    # clicked effect
    sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    ;;
esac
