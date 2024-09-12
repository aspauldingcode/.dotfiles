#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"
# Function to press the brightness up key
brightness_up() {
  osascript -e 'tell application "System Events" to key code 144'
}

# Function to press the brightness down key
brightness_down() {
  osascript -e 'tell application "System Events" to key code 145'
}

# Adjust brightness based on the provided number of times
brightness() {
  local times=$1

  if [[ $times -gt 0 ]]; then
    for ((i = 0; i < times; i++)); do
      brightness_up
    done
  elif [[ $times -lt 0 ]]; then
    for ((i = 0; i < -times; i++)); do
      brightness_down
    done
  fi
}

brightness_change() {
  case $INFO in
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

  sketchybar --set backlight label="$ICON $INFO%" highlight.color=$base07 # add the icon and the percentage
}

sketchybar --add item backlight.popup popup.backlight \
  --set backlight.popup label="Display Brightness" \
  label.padding_left=10 \
  label.padding_right=10

# Handle mouse events
case "$SENDER" in
"brightness_change")
  brightness_change
  ;;
"mouse.scrolled")
  # Adjust brightness using the brightness function
  brightness $SCROLL_DELTA
  ;;
"mouse.entered")
  sketchybar --set backlight popup.drawing=on
  ;;
"mouse.exited" | "mouse.exited.global")
  sketchybar --set backlight popup.drawing=off
  ;;
"mouse.clicked")
  open /System/Library/PreferencePanes/Displays.prefPane
  ;;
"routine")
  # Update brightness info periodically
  ;;
esac