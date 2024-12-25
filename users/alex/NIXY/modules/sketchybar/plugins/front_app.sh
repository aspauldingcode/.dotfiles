#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

#FIXME: USE https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1633997
update_sketchybar_label() {
    CURRENT_APP_NAME_AND_WINDOW=$(
    $yabai -m query --windows --window | $jq -r '"\(.title) • \(.app)"'
    )

    limit=25
    # Trim the string to 25 characters and append "…" if needed
    if [ "$CURRENT_APP_NAME_AND_WINDOW" = "no window" ]; then
        CURRENT_WINDOW_TITLE=""
    else
        CURRENT_WINDOW_TITLE=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -c -$limit)
        [ ${#CURRENT_APP_NAME_AND_WINDOW} -gt $limit ] && CURRENT_WINDOW_TITLE+="…"
    fi
    sketchybar --set $NAME label="$CURRENT_WINDOW_TITLE"
    sketchybar --add item $NAME.popup popup.$NAME \
        --set $NAME.popup label="$CURRENT_APP_NAME_AND_WINDOW" \
        label.padding_left=10 \
        label.padding_right=10
}

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
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
    # Use the CURRENT_APP_NAME_AND_WINDOW info
    APP_NAME=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -d' ' -f1)
    
    # Check if the front application is Alacritty
    if [ "$APP_NAME" = "Alacritty" ]; then
      # Send Command + W to close the window
      $osascript -e 'tell application "System Events" to keystroke "w" using {command down}'
    fi

    # button clicked effect
    sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
  ;;
esac

update_sketchybar_label