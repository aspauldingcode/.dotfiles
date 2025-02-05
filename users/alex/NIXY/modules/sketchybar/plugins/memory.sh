#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

MEMORY=$(vm_stat | awk '/Pages free:/ {free=$3} /Pages active:/ {active=$3} /Pages inactive:/ {inactive=$3} /Pages speculative:/ {speculative=$3} END {total=free + active + inactive + speculative; used=active + inactive; print int(100*used/total)}')

$SKETCHYBAR_EXEC --set $NAME label="$MEMORY%" icon=$MEMORY_ICON

MEMORY_USED=$(vm_stat | awk '/Pages active:/ {active=$3} /Pages inactive:/ {inactive=$3} /Pages speculative:/ {speculative=$3} END {used=active + inactive + speculative; printf "%.1f", used * 4096 / 1024 / 1024 / 1024}')
$SKETCHYBAR_EXEC --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="${MEMORY_USED}GiB used" \
    label.padding_left=10 \
    label.padding_right=10

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
    # clicked effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    # Update battery info periodically
    #update_battery
    ;;
esac
