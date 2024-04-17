#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
ITEM_DIR="$HOME/.config/sketchybar/items"
SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"
POPUP_TOGGLE_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

# ACTIVE_SPACE=$(yabai -m query --spaces --space | jq '.index')
SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

bar=(
  height=40
  corner_radius=10
  position=top
  color=$STATUS
  border_color=$GREY # why didn't that work?
  border_width=2
  y_offset=10
  sticky=off
  margin=13 # Margin around the bar
)

sketchybar --bar "${bar[@]}"

defaults=(
  updates=when_shown
  icon.drawing=on
  # icon.font="Hack Nerd Font Mono:Regular:20.0"
  icon.color=$WHITE
  label.font="JetBrains Mono:Regular:13.0"
  label.drawing=on
  label.color=$WHITE
  popup.background.color=$STATUS
  popup.background.corner_radius=10
  popup.background.border_width=2
  popup.background.border_color=$PURPLE
  popup.y_offset=8
)

sketchybar --default "${defaults[@]}"

datetime=(
  background.color=$TEMPUS         # Set this color to your background color for popups!
  icon.padding_left=15
  label.padding_left=5
  label.padding_right=15
  background.height=19 
  background.corner_radius=10
  popup.horizontal=on               # FIXME: FIGURE OUT HOW TO MAKE CALENDAR WITHOUT THIS!
  popup.align=center
  update_freq=60                    # required for datetime clock!
  script="$PLUGIN_DIR/datetime.sh"
  popup.height=160                  # REQUIRED for popup to work properly.
  background.corner_radius=10
)

wifi=(
  script="$PLUGIN_DIR/wifi.sh"
  #click_script="$POPUP_TOGGLE_SCRIPT"
  label.padding_left=5
  label.padding_right=5
  update_freq=10
  popup.align=center
)

battery=(
  script="$PLUGIN_DIR/battery.sh"
  update_freq=120
  updates=on
  #click_script="$POPUP_TOGGLE_SCRIPT"
  #label.padding_left=5
  #label.padding_right=5
  icon.padding_left=6
  icon.padding_right=8
  popup.align=center
)

volume=(
  script="$PLUGIN_DIR/volume.sh"
  updates=on
  icon.padding_left=10
  label.padding_right=5
)

mail=(
  # background.color=$TEMPUS
  background.height=25
  corner_radius=8
  background.padding_left=5 # because it is leftmost of the bracket.
  icon.padding_left=5 
  icon.padding_right=5
  icon.drawing=on
  icon="$MAIL"
  script="$PLUGIN_DIR/mail.sh"
  #click_script="$POPUP_TOGGLE_SCRIPT"
  update_freq=60
)

cava=(
  update_freq=0
  script="$PLUGIN_DIR/cava.sh"
  label.drawing=on
  label.font="Hack Nerd Font Mono:Regular:13.0"
  icon.drawing=off
  label="cava"
  label.padding_left=4
  label.padding_right=4
)

spotify=(
  #click_script="$POPUP_TOGGLE_SCRIPT"
  popup.horizontal=on
  popup.align=center
  popup.height=100
  icon=$SPOTIFY
  icon.padding_right=18
  icon.padding_left=18
  background.color=$TEMPUS
  background.height=19
  background.corner_radius=10
  #background.padding_left=3
  background.padding_right=3
  script="$PLUGIN_DIR/spotify.sh"
  update_freq=5
)

ram=(
  icon=$RAM
  icon.padding_left=15
  script="$PLUGIN_DIR/ram.sh"
  label.padding_right=15
  label.padding_left=10
  update_freq=4
  background.corner_radius=10
  background.color=$TEMPUS
  background.height=19
  background.padding_left=-6
  background.padding_right=3
  background.border_color=$PURPLE
)

cpu=(
  icon=$CPU
  icon.padding_left=15
  script="$PLUGIN_DIR/cpu.sh"
  label.padding_left=10
  label.padding_right=15
  update_freq=4
)

apple=(
  script="$PLUGIN_DIR/apple.sh"
  #click_script="$POPUP_TOGGLE_SCRIPT"
  label=$APPLE
  label.padding_right=15
  label.padding_left=15
  background.color=$TEMPUS
  background.height=19
  background.corner_radius=10
  background.padding_left=3
  background.padding_right=3
  popup.align=left
)

space_bg=(
  background.color=$SPACEBG
  background.height=19
  background.corner_radius=50
)

## Adding sketchybar Items:






# Left Items
sketchybar --add item apple left \
  --set apple "${apple[@]}" \
  --subscribe apple mouse.clicked mouse.entered mouse.exited mouse.exited.global





# Stupid spaces!
# REMOVE ALL SPACES to start clean.
# DISPLAY_INFO=$(yabai -m query --displays)
# num_displays=$(echo "$DISPLAY_INFO" | jq length)
# while true; do
#   # Get the current number of spaces
#   max_space_index=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
#   echo "Max Space Index: $max_space_index"
#   # Initial check for empty spaces
#   for ((sid=1; sid<=max_space_index; sid++)); do
#     windows_count=$(yabai -m query --spaces --space $sid | jq '.windows | length')
#     echo "Space $sid has $windows_count windows"
#     if [ "$windows_count" -eq 0 ]; then
#       echo "Removing Space $sid"
#       if yabai -m space $sid --destroy 2>&1 | grep -q "acting space is the last user-space on the source display and cannot be destroyed"; then
#         echo "Encountered the specific error. Exiting the loop."
#         exit
#       fi
#     fi
#   done
#   # Repeatedly check for and remove empty spaces
#   removed=false
#   # Iterate through spaces dynamically
#   for ((sid=1; sid<=max_space_index; sid++)); do
#     # Check if the space still exists
#     if yabai -m query --spaces --space $sid >/dev/null 2>&1; then
#       windows_count=$(yabai -m query --spaces --space $sid | jq '.windows | length')
#       echo "Space $sid has $windows_count windows"
#       if [ "$windows_count" -eq 0 ]; then
#         echo "Removing Space $sid"
#         if yabai -m space $sid --destroy 2>&1 | grep -q "acting space is the last user-space on the source display and cannot be destroyed"; then
#           echo "Encountered the specific error. Exiting the loop."
#           exit
#         fi
#         removed=true
#         break  # Exit the loop to recheck indices
#       fi
#     fi
#   done
#   # Break out of the loop if no empty spaces were removed
#   if [ "$removed" = false ]; then
#     break
#   fi
# done

#Define variables!
#How many displays are there?
max_displays=$(yabai -m query --displays | jq 'max_by(.index) | .index')

#How many spaces are there?
max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index' )

#Current active space!
current_space=$(yabai -m query --spaces --space | jq -r '.index')

#Current active display!
current_display=$(yabai -m query --displays --display | jq -r '.index')

#how to destroy spaces on all displays?
# for loop through max_displays
# for i in max_displays:
#destroy empty spaces on source display
#for loop:
# $(yabai -m space 1 --destroy)
#until you hit this error:
#"acting space is the last user-space on the source display and cannot be destroyed."
#Then
#destory empty spaces on the next display
#for loop
# $(yabai -m space max_displays[i] --destroy) # kinda like this?


#focus on a space
#yabai -m spsace --focus n 
# if space n is not created, create it 
# the error will be:
# could not locate space with mission-control index 'n'.
# n needs to be the variable of the space number.
# better way is "for max_spaces, does n exceed it?"
# if n > max_spaces, 
#     run the folling (n - max_spaces) times to reach output of space n available
#     iterations=(n - max_spaces)
#     for iterations, 
#         yabai -m space --create
# fi
# yabai -m space --focus n




#Define variables!
#How many displays are there?
max_displays=$(yabai -m query --displays | jq 'max_by(.index) | .index')

#How many spaces are there?
max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index' )

#Current active space!
current_space=$(yabai -m query --spaces --space | jq -r '.index')

#Current active display!
current_display=$(yabai -m query --displays --display | jq -r '.index')

# Focus on a space
# If space n is not created, create it
# n=5 # Change n to the desired space number
# if [ $n -gt $max_spaces ]; then
#     iterations=$((n - max_spaces))
#     for ((i=0; i<iterations; i++)); do
#         yabai -m space --create
#         #reassign max_spaces:
#         max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
#     done
# fi
# # then, focus on space n
# yabai -m space --focus $n






# Add only open spaces to Sketchybar
for ((i=1; i<=max_spaces; i++)); do
  sid=$(($i))
  sketchybar --add space space.$sid left \
    --set space.$sid space=$sid \
    ignore_association=on \
    icon=${SPACE_ICONS[i-1]} \
    background.color=0x44ffffff \
    icon.highlight_color=0x00000000 \
    background.corner_radius=5 \
    icon.padding_left=5 \
    icon.padding_right=5 \
    background.height=20 \
    background.drawing=off \
    label.drawing=off \
    script="$PLUGIN_DIR/space.sh" \
    click_script="yabai -m space --focus $sid" \
    icon.font="JetBrains Mono:Regular:13.0"
done











sketchybar --add item separator_left left \
  --set separator_left "${separator_left[@]}" \
    icon= \
    padding_left=8 \
    label.drawing=off \
  --add item front_app left \
  --set front_app "${front_app[@]}" \
    script="$PLUGIN_DIR/front_app.sh" \
    click_script="yabai -m window --close" \
    icon.drawing=on \
    label.padding_left=15 \
    label.padding_right=15 \
    --subscribe front_app front_app_switched mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item active_app left \
   --set active_app "${active_app[@]}" \
   --subscribe front_app front_app_switched












# Center Items
sketchybar --add item volume center \
  --set volume "${volume[@]}" \
  --subscribe volume volume_change mouse.scrolled mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item datetime center \
  --set datetime "${datetime[@]}" \
  --subscribe datetime system_woke mouse.clicked mouse.entered mouse.exited mouse.exited.global # REQUIRED events for hover popup.
sketchybar --add item cava center \
  --set cava "${cava[@]}"
  # --add item spotify_label center \
  # --set spotify_label "${spotify_label[@]}"
sketchybar --add event spotify_change $SPOTIFY_EVENT \
  --add item spotify center \
  --set spotify "${spotify[@]}" \
  --subscribe spotify mouse.clicked mouse.entered mouse.exited mouse.exited.global

# Right Items
sketchybar --add item ram right \
  --set ram "${ram[@]}"
  --subscribe ram mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item cpu right \
  --set cpu "${cpu[@]}"
  --subscribe cpu mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar  --add item separator_right right \
  --set separator_right "${separator_right[@]}" \
    icon= \
    padding_right=0 \
    label.drawing=off 
sketchybar --add item battery right \
  --set battery "${battery[@]}" \
  --subscribe battery power_source_change system_woke mouse.entered mouse.exited mouse.exited.global

rm -f /tmp/sketchybar_speed
rm -f /tmp/sketchybar_wifi
sketchybar --add item wifi right \
  --set wifi "${wifi[@]}" \
  --subscribe wifi system_woke mouse.entered mouse.exited mouse.exited.global

sketchybar --add item mail right \
  --set mail "${mail[@]}"

brackets=(
  background.color=$STATUS
  background.height=25
  background.corner_radius=20
  background.border_color=$PURPLE
  background.border_width=2
)

sketchybar --add bracket lbracket apple separator_left front_app left \
  --set lbracket "${brackets[@]}"
sketchybar --add bracket cbracket volume datetime cava spotify center \
  --set cbracket "${brackets[@]}"
sketchybar --add bracket rbracket wifi battery separator_right mail ram cpu right \
  --set rbracket "${brackets[@]}"

sketchybar --update
