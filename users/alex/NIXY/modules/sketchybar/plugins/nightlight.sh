#    ~  nightlight --help
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

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# Adjust nightlight temperature based on the provided number of times
adjust_temp() {
  local delta=$1
  local current_temp_percentage=$($nightlight temp | grep -o '[0-9]\+')
  local new_temp=$((current_temp_percentage + delta))

  if [[ $new_temp -gt 100 ]]; then
    new_temp=100
  elif [[ $new_temp -lt 0 ]]; then
    new_temp=0
  fi

  $nightlight temp $new_temp
}

# Convert percentage to temperature value. 0% = 6500K, 100% = 3500K
current_temp() {
  local percentage=$1
  local temp=$((6500 - (percentage * 30)))
  echo $temp
}

update_icon() {
  current_temp_percentage=$($nightlight temp | grep -o '[0-9]\+')
  temp_value=$(current_temp $current_temp_percentage)
  status=$($nightlight status)
  status_label="off"

  if [[ $status == *"on"* ]]; then
    status_label="on"
  elif [[ $status == *"off"* ]]; then
    status_label="off"
  fi

  case $current_temp_percentage in
  [8-9][0-9] | 100)
    ICON=$BACKLIGHT_5
    ;;
  [6-7][0-9])
    ICON=$BACKLIGHT_4
    ;;
  [4-5][0-9])
    ICON=$BACKLIGHT_6
    ;;
  [0-3][0-9])
    ICON=$BACKLIGHT_6
    ;;
  *)
    ICON=$BACKLIGHT_7
    ;;
  esac

  # add the icon, percentage, temperature value, and status
  $SKETCHYBAR_EXEC --set nightlight label="$ICON $current_temp_percentage%"
  $SKETCHYBAR_EXEC --set nightlight.popup label="Nightlight Temperature: ${temp_value}K ($status_label)"
}

$SKETCHYBAR_EXEC --add item nightlight.popup popup.nightlight \
  --set nightlight.popup label="Nightlight Temperature: $current_temp ($status_label)" \
  label.padding_left=10 \
  label.padding_right=10

# Ensure the icon is updated with the current temperature percentage when the plugin is first added
update_icon

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
  $SKETCHYBAR_EXEC --set $NAME popup.drawing=on
  
  # highlight effect
  $SKETCHYBAR_EXEC --set $NAME icon.highlight=on label.highlight=on icon.highlight_color=$base07 label.highlight_color=$base07
  ;;
"mouse.exited" | "mouse.exited.global")
  $SKETCHYBAR_EXEC --set $NAME popup.drawing=off
  
  # unhighlight effect
  $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off
  ;;
"mouse.clicked")
  $nightlight toggle
  
  # clicked effect
  $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
  $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
  $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
  ;;
"routine")
  # Update nightlight info periodically
  update_icon
  ;;
esac