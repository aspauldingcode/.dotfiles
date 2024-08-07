#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

RUNNING=$(osascript -e 'if application "Mail" is running then return 0')
COUNT=0

mail_popup=(
  sticky=on #WTF doesn't change anything?
  icon=$MAIL_UNREAD
  #icon.padding_left=10
  label.y_offset=0
  label.font="DejaVu Mono:Bold:12.0"
  height=10
  blur_radius=100
)

sketchybar --add item mail.popup popup.mail \
  --set mail.popup "${mail_popup[@]}" \

if [ "$RUNNING" = "0" ]; then
  COUNT=$(osascript -e 'tell application "Mail" to return the unread count of inbox')
  if [ "$COUNT" -gt "0" ]; then
    sketchybar --set $NAME icon=$MAIL_UNREAD
    sketchybar --set mail.popup label="You have $COUNT unread emails"
  else
    sketchybar --set $NAME icon=$MAIL
    sketchybar --set mail.popup label="You have $COUNT unread emails"
  fi
else
  sketchybar --set $NAME icon=$MAIL \
  sketchybar --set mail.popup label="Mail is not running"
fi
