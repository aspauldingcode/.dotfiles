#!/bin/sh

#FIXME: Add bluetooth headphone indicator with Battery:https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1549450
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

volume_change() {
  case $INFO in
  [7-9][0-9] | 100)
    ICON=$VOLUME
    ;;
  [4-6][0-9])
    ICON=$VOLUME_66
    ;;
  [1-3][0-9])
    ICON=$VOLUME_33
    ;;
  [1-9])
    ICON=$VOLUME_10
    ;;
  0)
    ICON=$VOLUME_0
    ;;
  *) ICON=$VOLUME_100 ;;
  esac

  sketchybar --set volume label="$ICON $INFO%" #add the icon and the percentage
}

sketchybar --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="$(system_profiler SPAudioDataType -xml | awk -F'<|>' '/<dict>/ {output_name=""; default_output=0} /<key>_name<\/key>/{getline; output_name=$3} /<key>coreaudio_default_audio_output_device<\/key>/{default_output=1} /<\/dict>/ && default_output {print output_name; exit}')" \
  label.padding_left=10 \
  label.padding_right=10 \

# Handle mouse events
case "$SENDER" in
"volume_change")
  volume_change
  ;;
"mouse.scrolled")
  # Extract the delta value from INFO (assuming it's in JSON format)
  osascript -e "set volume output volume (output volume of (get volume settings) + $SCROLL_DELTA)"
  ;;
  "mouse.entered")
    #sleep 1
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
    open /System/Library/PreferencePanes/Sound.prefPane

    # clicked effect
    sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    # Update battery info periodically
    #update_battery
    ;;
esac

