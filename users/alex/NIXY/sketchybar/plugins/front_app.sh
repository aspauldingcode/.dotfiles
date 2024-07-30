#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

#FIXME: USE https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1633997
update_sketchybar() {
    CURRENT_APP_NAME_AND_WINDOW=$($osascript -e 'global frontApp, frontAppName, windowTitle

    set windowTitle to ""
    tell application "System Events"
        set frontApp to first application process whose frontmost is true
        set frontAppName to name of frontApp
        set windowTitle to "no window"
        tell process frontAppName
            if exists (1st window whose value of attribute "AXMain" is true) then
                tell (1st window whose value of attribute "AXMain" is true)
                    set windowTitle to value of attribute "AXTitle"
                end tell
            end if
        end tell
    end tell

    return windowTitle')

    limit=25
    # Trim the string to 25 characters and append "..." if needed
    
    if [ "$CURRENT_APP_NAME_AND_WINDOW" = "no window" ]; then
    CURRENT_WINDOW_TITLE=""
    else
        CURRENT_WINDOW_TITLE=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -c -$limit)
    [ ${#CURRENT_APP_NAME_AND_WINDOW} -gt $limit ] && CURRENT_WINDOW_TITLE+="..."
    fi
    sketchybar --set $NAME label="$CURRENT_WINDOW_TITLE" 
    sketchybar --add item $NAME.popup popup.$NAME \
  --set $NAME.popup label="$CURRENT_APP_NAME_AND_WINDOW" \
    label.padding_left=10 \
    label.padding_right=10
}

update_sketchybar
# Replace $NAME with the actual name you want to set for sketchybar
# For example: NAME=my_window_label update_sketchybar

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    #sleep 1
    sketchybar --set $NAME popup.drawing=on
    #echo "Mouse Hovered in $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    #echo "Mouse left hover of $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.clicked")
    # Use the CURRENT_APP_NAME_AND_WINDOW info
    APP_NAME=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -d' ' -f1)
    
    # Check if the front application is Alacritty
    if [ "$APP_NAME" = "Alacritty" ]; then
      # Send Command + W to close the window
      $osascript -e 'tell application "System Events" to keystroke "w" using {command down}'
    fi
    ;;
  "routine")
    # Update battery info periodically
    #update_battery
    ;;
esac

source "$HOME/.config/sketchybar/plugins/yabai_i3_switch.sh" # in charge of detecting if we are on a x11.bin window or not. Fixes mouse resize.
yabai_i3_switch # run the working one instead. 