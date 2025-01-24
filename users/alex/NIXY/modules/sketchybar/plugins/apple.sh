#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Get fastfetch output and format it for sketchybar
FASTFETCH_OUTPUT=$(fastfetch --pipe --logo none --disable-linewrap --config "$PLUGIN_DIR/fastfetch_config.jsonc")

# Create array of lines from fastfetch output
IFS=$'\n' read -d '' -r -a LINES <<< "$FASTFETCH_OUTPUT"

# Set popup height on apple item
$SKETCHYBAR_EXEC --set apple popup.height=20

# Add each line as a separate item in the popup
for i in "${!LINES[@]}"; do
  $SKETCHYBAR_EXEC --add item fastfetch.line.$i popup.apple \
    --set fastfetch.line.$i \
      label="${LINES[$i]}" \
      label.padding_left=10 \
      label.padding_right=10 \
      label.font="JetBrainsMono Nerd Font:Regular:12.0"
done

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=on
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=on label.highlight=on
    ;;
  "mouse.exited" | "mouse.exited.global")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=off
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off
    ;;
  "mouse.clicked")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=toggle
    ;;
esac
