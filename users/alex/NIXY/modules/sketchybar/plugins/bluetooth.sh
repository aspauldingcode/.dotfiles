#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

BLUETOOTH_STATUS=$(system_profiler SPBluetoothDataType | grep -i "Bluetooth Power" | awk '{print $3}')

if [ "$BLUETOOTH_STATUS" = "On" ]; then
  ICON="$BLUETOOTH_ON"
else
  ICON="$BLUETOOTH_OFF"
fi

# Set the bluetooth icon
sketchybar --set $NAME icon="$ICON"

# Handle mouse events for hover status
case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME icon.highlight=on
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME icon.highlight=off
    ;;
esac
