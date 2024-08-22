#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"
POPUP_TOGGLE_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

#events
sketchybar --add event window_focus \
           --add event title_change \
           --add event windows_on_spaces

# module styles
bar=(
  height=40
  corner_radius=10
  position=top
  color=$base00
  border_color=$base05 # why didn't that work?
  border_width=2
  y_offset=13
  sticky=off
  margin=13 # Margin around the bar
  # blur_radius=15 # add background blur
)

defaults=(
  updates=when_shown
  icon.drawing=on
  # icon.font="Hack Nerd Font Mono:Regular:20.0"
  icon.color=$base05
  label.font="JetBrains Mono:Regular:13.0"
  label.drawing=on
  label.color=$base05
  popup.background.color=$base00
  popup.background.corner_radius=10
  popup.background.border_width=2
  popup.background.border_color=$base07
  # popup.blur_radius=15
  popup.y_offset=0
)

sketchybar --default "${defaults[@]}"

# space_config=(
#     ignore_association=on
#     updates=on \
#     script="$PLUGIN_DIR/add_spaces_sketchybar.sh"
#     update_freq=0
#     # click_script="$yabai -m space --focus $sid"
# )

datetime=(
  background.color=$base02         # Set this color to your background color for popups!
  icon.padding_left=15
  label.padding_left=5
  label.padding_right=15
  padding_left=3
  padding_right=3
  background.height=19 
  background.corner_radius=10
  popup.horizontal=on               # FIXME: FIGURE OUT HOW TO MAKE CALENDAR WITHOUT THIS!
  popup.align=center
  update_freq=60                    # required for datetime clock!
  script="$PLUGIN_DIR/datetime.sh"
  popup.height=160                  # REQUIRED for popup to work properly.
)

wifi=(
  script="$PLUGIN_DIR/wifi.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh wifi"
  label.padding_left=5
  label.padding_right=5
  update_freq=10
  popup.align=center
)

battery=(
  script="$PLUGIN_DIR/battery.sh"
  update_freq=120
  updates=on
  click_script="$PLUGIN_DIR/open_menubar_items.sh battery"
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

backlight=(
  script="$PLUGIN_DIR/backlight.sh"
  updates=on
  icon.padding_left=5
  label.padding_right=5
)

nightlight=(
  script="$PLUGIN_DIR/nightlight.sh"
  updates=on
  icon.padding_left=5
  label.padding_right=5
)

mail=(
  # background.color=$base02
  background.height=25
  corner_radius=8
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
  label.padding_right=10
)

# spotify=(
#   #click_script="$POPUP_TOGGLE_SCRIPT"
#   popup.horizontal=on
#   popup.align=center
#   popup.height=100
#   icon=$SPOTIFY
#   icon.padding_right=18
#   icon.padding_left=18
#   background.color=$base02
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
  background.color=$base02
  background.height=19
  background.padding_left=-6
  background.padding_right=3
  background.border_color=$base07
  popup.align=right
)

cpu=(
  icon=$CPU
  icon.padding_left=15
  script="$PLUGIN_DIR/cpu.sh"
  label.padding_left=10
  label.padding_right=15
  update_freq=4
  popup.align=right
)

apple=(
  script="$PLUGIN_DIR/apple.sh"
  #click_script="$POPUP_TOGGLE_SCRIPT"
  label=$APPLE
  label.padding_right=15
  label.padding_left=15
  background.color=$base02
  background.height=19
  background.corner_radius=10
  background.padding_left=3
  background.padding_right=3
  popup.align=left
)

sketchybar --bar "${bar[@]}"

## Adding sketchybar Items:
# Left Items
sketchybar --add item apple left \
  --set apple "${apple[@]}" \
  --subscribe apple mouse.clicked mouse.entered mouse.exited mouse.exited.global

# sketchybar --add space space left \
#   --set space "${space_config[@]}" \
#  # --subscribe space space_change space_windows_change front_app_switched display_change

##### Adding Mission Control Space Indicators #####
# Let's add some mission control spaces:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item
# to indicate active and available mission control spaces.

for i in {1..10}
do
  sid="$i"
  space=(
    space="$sid"
    icon="$i"
    icon.padding_left=4
    icon.padding_right=5
    # icon.margin_left=10
    # icon.margin_right=10
    background.color=$base02
    background.corner_radius=5
    background.height=13
    # background.width=10
    label.drawing=off
    icon.font="JetBrains Mono:Regular:10.0"
    script="$PLUGIN_DIR/space.sh"
    click_script="yabai -m space --focus $sid"
  )
  sketchybar --add space space."$sid" left --set space."$sid" "${space[@]}" ignore_association=on
done

sketchybar --add item separator_left left \
  --set separator_left \
    icon= \
    padding_left=8 \
    label.drawing=off

sketchybar --add item front_app left \
  --set front_app \
    script="$PLUGIN_DIR/front_app.sh" \
    click_script="if [ \"$($yabai -m query --windows --window | $jq -r '.app')\" = \"Alacritty\" ]; then $osascript -e 'tell application \"System Events\" to keystroke \"w\" using {command down}'; else $yabai -m window --close; fi" \
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
    update_freq=1 \
    script="$PLUGIN_DIR/fullscreen_lock.sh"
# Center Items
sketchybar --add item volume center \
  --set volume "${volume[@]}" \
  --subscribe volume volume_change mouse.scrolled mouse.clicked mouse.entered mouse.exited mouse.exited.global

sketchybar --add item backlight center \
  --set backlight "${backlight[@]}" \
  --subscribe backlight brightness_change mouse.scrolled mouse.clicked mouse.entered mouse.exited mouse.exited.global

sketchybar --add item nightlight center \
  --set nightlight "${nightlight[@]}" \
  --subscribe nightlight mouse.scrolled mouse.clicked mouse.entered mouse.exited mouse.exited.global

sketchybar --add item datetime center \
  --set datetime "${datetime[@]}" \
  --subscribe datetime system_woke mouse.clicked mouse.entered mouse.exited mouse.exited.global 

sketchybar --add item cava center \
  --set cava "${cava[@]}"
sketchybar --add event spotify_change $SPOTIFY_EVENT \
  --add item spotify center \
  --set spotify "${spotify[@]}" \
  --subscribe spotify mouse.clicked mouse.entered mouse.exited mouse.exited.global

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

[ -f "/tmp/sketchybar_speed" ] && rm "/tmp/sketchybar_speed"
[ -f "/tmp/sketchybar_wifi" ] && rm "/tmp/sketchybar_wifi"
sketchybar --add item wifi right \
  --set wifi "${wifi[@]}" \
  --subscribe wifi system_woke mouse.entered mouse.exited mouse.exited.global

sketchybar --add item mail right \
  --set mail "${mail[@]}"

brackets=(
  background.color=$base00
  background.height=25
  background.corner_radius=20
  background.border_color=$base07
  background.border_width=1
)

# Define the alias_position for alias items
alias_position="right"  # You can change this to "center", "left", or any custom alias_position

# Add alias items with click actions
sketchybar --add alias "Control Center,BentoBox" $alias_position
sketchybar --set "Control Center,BentoBox" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh controlcenter"

sketchybar --add alias "Control Center,base0Dtooth" $alias_position
sketchybar --set "Control Center,base0Dtooth" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh base0Dtooth"

sketchybar --add alias "Control Center,UserSwitcher" $alias_position
sketchybar --set "Control Center,UserSwitcher" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh userswitcher"

sketchybar --add alias "UnnaturalScrollWheels,Item-0" $alias_position
sketchybar --set "UnnaturalScrollWheels,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh unnaturalscrollwheels"

sketchybar --add alias "macOS InstantView,Item-0" $alias_position
sketchybar --set "macOS InstantView,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh macosinstantview"

sketchybar --add alias "AltTab,Item-0" $alias_position
sketchybar --set "AltTab,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh alttab"

sketchybar --add alias "Karabiner-Menu,Item-0" $alias_position
sketchybar --set "Karabiner-Menu,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh karabiner-menu"

sketchybar --add alias "Background Music,Item-0" $alias_position
sketchybar --set "Background Music,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh backgroundmusic"

sketchybar --add alias "Flameshot,Item-0" $alias_position
sketchybar --set "Flameshot,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh flameshot"

sketchybar --add alias "KDE Connect,Item-0" $alias_position
sketchybar --set "KDE Connect,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
    click_script="$PLUGIN_DIR/open_menubar_items.sh kde-connect"


# sketchybar --add alias "Control Center,Clock" $alias_position
# sketchybar --set "Control Center,Clock" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_clock.scpt"

# sketchybar --add alias "Spotlight,Item-0" $alias_position
# sketchybar --set "Spotlight,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_spotlight.scpt"

# sketchybar --add alias "Control Center,WiFi" $alias_position
# sketchybar --set "Control Center,WiFi" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_wifi.scpt"

# sketchybar --add alias "Control Center,Battery" $alias_position
# sketchybar --set "Control Center,Battery" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_battery.scpt"

# sketchybar --add alias "Hidden Bar,hiddenbar_expandcollapse" $alias_position
# sketchybar --set "Hidden Bar,hiddenbar_expandcollapse" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_hiddenbar_expandcollapse.scpt"

# sketchybar --add alias "Control Center,AudioVideoModule" $alias_position
# sketchybar --set "Control Center,AudioVideoModule" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_audiovideomodule.scpt"

# sketchybar --add alias "TextInputMenuAgent,Item-0" $alias_position
# sketchybar --set "TextInputMenuAgent,Item-0" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_textinputmenuagent.scpt"

# sketchybar --add alias "Hidden Bar,hiddenbar_separate" $alias_position
# sketchybar --set "Hidden Bar,hiddenbar_separate" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_hiddenbar_separate.scpt"

# sketchybar --add alias "Hidden Bar,hiddenbar_terminate" $alias_position
# sketchybar --set "Hidden Bar,hiddenbar_terminate" alias.color=$base05 alias.scale=0.8 padding_left=-3 padding_right=-3-5 alias.update_freq=1 \
#     click_script="osascript /path/to/click_hiddenbar_terminate.scpt"

sketchybar --add item rbracket_padding_left right --set rbracket_padding_left icon.padding_right=4 icon.padding_left=4 icon="" # because it is leftmost of the bracket.

# https://felixkratz.github.io/SketchyBar/config/components#item-bracket----group-items-in-eg-colored-sections
sketchybar --add bracket lbracket apple space '/space\..*/' separator_left front_app left \
  --set lbracket "${brackets[@]}"
sketchybar --add bracket cbracket volume backlight nightlight datetime cava spotify center \
  --set cbracket "${brackets[@]}" 
sketchybar --add bracket rbracket "Control Center,BentoBox" "TextInputMenuAgent,Item-0" \
  "Control Center,UserSwitcher" "UnnaturalScrollWheels,Item-0" "macOS InstantView,Item-0" \
  "AltTab,Item-0" "Karabiner-Menu,Item-0" "Background Music,Item-0" "Flameshot,Item-0" \
  rbracket_padding_left wifi "Control Center,base0Dtooth" battery separator_right mail ram cpu right \
  --set rbracket "${brackets[@]}" 

#initialize states
printf "on\n" > "/tmp/sketchybar_state"
printf "on\n" > "/tmp/gaps_state"
dismiss-notifications # not working?
if [ -f "$HOME/.config/sketchybar/calendar_init_flag" ]; then
    rm "$HOME/.config/sketchybar/calendar_init_flag" # remove calendar flag at sketchybar launch if it exists
fi
sketchybar --update

# # Fetch the menu items from sketchybar query
# sleep 4
# /opt/homebrew/bin/sketchybar --query default_menu_items | $jq -r '.[]' | while IFS= read -r item; do /opt/homebrew/bin/sketchybar --set "$item" alias.update_freq=0; done && sleep 4
# # $yabai -m config menubar_opacity 0.0
# $toggle_sketchybar off