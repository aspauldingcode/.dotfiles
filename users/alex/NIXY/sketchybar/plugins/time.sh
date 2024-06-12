#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch.sh"

sketchybar --set $NAME label="$(date '+%H:%M')"

time_popup=(
  icon=$TIME
  icon.padding_left=10
  label="$(date '+%H:%M:%S')"
  label.padding_left=10
  label.padding_right=10
  label.font="DejaVu Mono:Bold:12.0"
  height=10
  blur_radius=100
)

sketchybar --add item time.popup popup.time \
  --set time.popup "${time_popup[@]}"
