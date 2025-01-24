#!/bin/sh

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
# source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

CPU=$(top -l 1 | awk '/^CPU usage:/ {print int($3)}')

$SKETCHYBAR_EXEC --set $NAME label="$CPU%" icon=$CPU_ICON

TOTAL_CPU_USAGE=$(top -l 1 | awk '/^CPU usage:/ {print int($3)}')
$SKETCHYBAR_EXEC --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="Total: $TOTAL_CPU_USAGE%" \
    label.padding_left=10 \
    label.padding_right=10

# cpu popup which shows usage per core/thread
# since apple silicon, doesn't have hyperthreading, the number of threads is the same as the number of cores.
NCPU=$(sysctl -n hw.ncpu)

for i in $(seq 0 $(($NCPU - 1))); do
  CPU_USAGE=$(ps -A -o %cpu | awk -v core=$i 'NR>1 {sum+=$1} END {print int(sum/NR)}')
  $SKETCHYBAR_EXEC --add item $NAME.core$i popup.$NAME \
    --set $NAME.core$i label="Core$i: $CPU_USAGE%" \
      label.padding_left=10 \
      label.padding_right=10
done

# Handle mouse events
case "$SENDER" in
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
    # button clicked effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    # Update battery info periodically
    #update_battery
    ;;
esac