#!/bin/sh
#
# if [ "$SENDER" = "front_app_switched" ]; then
#     CURRENT_APP_NAME_AND_WINDOW=$(osascript -e 'global frontApp, frontAppName, windowTitle
#
#     set windowTitle to ""
#     tell application "System Events"
#         set frontApp to first application process whose frontmost is true
#         set frontAppName to name of frontApp
#         set windowTitle to "no window"
#         tell process frontAppName
#             if exists (1st window whose value of attribute "AXMain" is true) then
#                 tell (1st window whose value of attribute "AXMain" is true)
#                     set windowTitle to value of attribute "AXTitle"
#                 end tell
#             end if
#         end tell
#     end tell
#
#     return windowTitle')
#
#     limit=25
#     # Trim the string to 25 characters and append "..." if needed
#     CURRENT_WINDOW_TITLE=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -c -$limit)
#     [ ${#CURRENT_APP_NAME_AND_WINDOW} -gt $limit ] && CURRENT_WINDOW_TITLE+="..."
#     
#     sketchybar --set $NAME label="$CURRENT_WINDOW_TITLE"
# fi

update_sketchybar() {
    CURRENT_APP_NAME_AND_WINDOW=$(osascript -e 'global frontApp, frontAppName, windowTitle

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
    CURRENT_WINDOW_TITLE=$(echo "$CURRENT_APP_NAME_AND_WINDOW" | cut -c -$limit)
    [ ${#CURRENT_APP_NAME_AND_WINDOW} -gt $limit ] && CURRENT_WINDOW_TITLE+="..."

    sketchybar --set $NAME label="$CURRENT_WINDOW_TITLE"
}

update_sketchybar
# Replace $NAME with the actual name you want to set for sketchybar
# For example: NAME=my_window_label update_sketchybar

