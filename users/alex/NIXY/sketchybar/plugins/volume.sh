#!/bin/sh
#FIXME: Add bluetooth headphone indicator with Battery:https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1549450
source "$HOME/.config/sketchybar/icons.sh"

volume_change() {
  case $INFO in
  [6-9][0-9] | 100)
    ICON=$VOLUME
    ;;
  [3-5][0-9])
    ICON=$VOLUME_66
    ;;
  [1-2][0-9])
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

  sketchybar --set volume_icon label="$ICON $INFO%" #add the icon and the percentage
}

mouse_clicked() {
  #osascript -e "set volume output volume 0"
  say hi
}

mouse_entered() {
  sleep 2
  sketchybar --set volume_icon popup.drawing=on
  sketchybar --set volume popup.drawing=on
}

mouse_exited() {
  sketchybar --set volume_icon popup.drawing=off
  sketchybar --set volume popup.drawing=off
}


case "$SENDER" in
"volume_change")
  volume_change
  ;;
"mouse.clicked")
  mouse_clicked
  ;;
"mouse.entered")
  mouse_entered
  ;;
"mouse.exited")
  mouse_exited
  ;;
esac
