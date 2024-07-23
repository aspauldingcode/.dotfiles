#    ~  nightlight --help
# nightlight v0.3.0
#   A CLI for configuring 'Night Shift' on macOS 🌕🌖🌗🌘🌑

# usage:
#   nightlight [--help] <command> [<args>]

# Available Commands By Category:

# manual on/off control:
#   on                       Turn Night Shift on (until scheduled stop)
#   off                      Turn Night Shift off (until scheduled start)
#   status                   View current on/off status
#   toggle                   Toggle on or off based on current status

# color temperature:
#   temp                     View temperature preference
#   temp <0-100|3500K-6500K> Set temperature preference (does not affect on/off)

# automated schedule:
#   schedule                 View the current schedule
#   schedule start           Start schedule from sunset to sunrise
#   schedule <from> <to>     Start a custom schedule (12 or 24-hour time format)
#   schedule stop            Stop the current schedule



#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# Adjust nightlight temperature based on the provided number of times
adjust_temp() {
  local delta=$1
  local current_temp=$(nightlight temp | grep -o '[0-9]\+')
  local new_temp=$((current_temp + delta))

  if [[ $new_temp -gt 100 ]]; then
    new_temp=100
  elif [[ $new_temp -lt 0 ]]; then
    new_temp=0
  fi

  nightlight temp $new_temp
}

update_icon() {
  local current_temp=$(nightlight temp | grep -o '[0-9]\+')
  case $current_temp in
  [8-9][0-9] | 100)
    ICON=$BACKLIGHT_7
    ;;
  [6-7][0-9])
    ICON=$BACKLIGHT_6
    ;;
  [4-5][0-9])
    ICON=$BACKLIGHT_6
    ;;
  [0-3][0-9])
    ICON=$BACKLIGHT_4
    ;;
  *)
    ICON=$BACKLIGHT_5
    ;;
  esac

  sketchybar --set nightlight label="$ICON $current_temp%" # add the icon and the percentage
}

sketchybar --add item nightlight.popup popup.nightlight \
  --set nightlight.popup label="Nightlight Temperature" \
  label.padding_left=10 \
  label.padding_right=10 \

# Handle mouse events
case "$SENDER" in
"brightness_change")
  update_icon
  ;;
"mouse.scrolled")
  # Adjust nightlight temperature using the adjust_temp function
  adjust_temp $SCROLL_DELTA
  update_icon
  ;;
"mouse.entered")
  sketchybar --set nightlight popup.drawing=on
  ;;
"mouse.exited" | "mouse.exited.global")
  sketchybar --set nightlight popup.drawing=off
  ;;
"mouse.clicked")
  nightlight toggle
  ;;
"routine")
  # Update nightlight info periodically
  update_icon
  ;;
esac