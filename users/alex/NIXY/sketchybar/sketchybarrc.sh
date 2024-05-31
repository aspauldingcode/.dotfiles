#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
ITEM_DIR="$HOME/.config/sketchybar/items"
# SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"
POPUP_TOGGLE_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

#events
sketchybar --add event window_focus \
           --add event title_change \
           --add event windows_on_spaces \


# module styles
bar=(
  height=40
  corner_radius=10
  position=top
  color=$STATUS
  border_color=$GREY # why didn't that work?
  border_width=2
  y_offset=13
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

space_config=(
    ignore_association=on
    updates=on \
    script="$PLUGIN_DIR/add_spaces_sketchybar.sh"
    # click_script="yabai -m space --focus $sid"
)

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

# cava=(
#   update_freq=0
#   script="$PLUGIN_DIR/cava.sh"
#   label.drawing=on
#   label.font="Hack Nerd Font Mono:Regular:13.0"
#   icon.drawing=off
#   label="cava"
#   label.padding_left=4
#   label.padding_right=4
# )

# spotify=(
#   #click_script="$POPUP_TOGGLE_SCRIPT"
#   popup.horizontal=on
#   popup.align=center
#   popup.height=100
#   icon=$SPOTIFY
#   icon.padding_right=18
#   icon.padding_left=18
#   background.color=$TEMPUS
#   background.height=19
#   background.corner_radius=10
#   #background.padding_left=3
#   background.padding_right=3
#   script="$PLUGIN_DIR/spotify.sh"
#   update_freq=5
# )

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

## Adding sketchybar Items:
# Left Items
sketchybar --add item apple left \
  --set apple "${apple[@]}" \
  --subscribe apple mouse.clicked mouse.entered mouse.exited mouse.exited.global

sketchybar --add space space left \
  --set space "${space_config[@]}" \
  --subscribe space space_change space_windows_change front_app_switched display_change

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
    updates=on \
    --subscribe front_app front_app_switched window_focus windows_on_spaces title_change mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item active_app left \
    --set active_app "${active_app[@]}"

sketchybar --add item fullscreen_locker left \
  --set fullscreen_locker \
    updates=on \
    icon.drawing=off \
    label.drawing=off \
    padding=0 \
    update_freq=1 \
    script="$PLUGIN_DIR/fullscreen_lock.sh" \
    --subscribe fullscreen_locker always
    
# Center Items
sketchybar --add item volume center \
  --set volume "${volume[@]}" \
  --subscribe volume volume_change mouse.scrolled mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item datetime center \
  --set datetime "${datetime[@]}" \
  --subscribe datetime system_woke mouse.clicked mouse.entered mouse.exited mouse.exited.global 

# sketchybar --add item cava center \
  # --set cava "${cava[@]}"
# sketchybar --add event spotify_change $SPOTIFY_EVENT \
  # --add item spotify center \
  # --set spotify "${spotify[@]}" \
  # --subscribe spotify mouse.clicked mouse.entered mouse.exited mouse.exited.global

# Right Items
sketchybar --add item ram right \
  --set ram "${ram[@]}" \
  --subscribe ram mouse.clicked mouse.entered mouse.exited mouse.exited.global
sketchybar --add item cpu right \
  --set cpu "${cpu[@]}" \
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

# https://felixkratz.github.io/SketchyBar/config/components#item-bracket----group-items-in-eg-colored-sections
sketchybar --add bracket lbracket apple space '/space\..*/' separator_left front_app left \
  --set lbracket "${brackets[@]}"
sketchybar --add bracket cbracket volume datetime cava spotify center \
  --set cbracket "${brackets[@]}"
sketchybar --add bracket rbracket wifi battery separator_right mail ram cpu right \
  --set rbracket "${brackets[@]}"

sketchybar --update
