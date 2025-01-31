#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"
POPUP_TOGGLE_SCRIPT="$SKETCHYBAR_EXEC --set \$NAME popup.drawing=toggle"

#events
$SKETCHYBAR_EXEC --add event window_focus \
           --add event title_change \
           --add event windows_on_spaces \
           --add event spotify_change $SPOTIFY_EVENT 

# module styles
bar=(
  height=40
  corner_radius=10
  position=top
  color=$base00
  border_color=$base05
  icon.highlight_color=$base07
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
  icon.highlight_color=$base07
  label.font="JetBrains Mono:Regular:13.0"
  label.drawing=on
  label.color=$base05
  label.highlight_color=$base07
  popup.background.color=$base00
  popup.background.corner_radius=10
  popup.background.border_width=2
  popup.background.border_color=$base07
  # popup.blur_radius=15
  popup.y_offset=0
  popup.height=23
)

$SKETCHYBAR_EXEC --default "${defaults[@]}"

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
  icon.padding_left=5
  icon.padding_right=5
  update_freq=10
  popup.align=center
)

battery=(
  script="$PLUGIN_DIR/battery.sh"
  update_freq=120
  updates=on
  click_script="$PLUGIN_DIR/open_menubar_items.sh battery"
  icon.padding_left=5
  icon.padding_right=5
  popup.align=center
)

bluetooth=(
  script="$PLUGIN_DIR/bluetooth.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh bluetooth"
  icon=$BLUETOOTH_UNKNOWN
  popup.align=right
  icon.padding_left=5
  icon.padding_right=5
  update_freq=5
)

volume=(
  script="$PLUGIN_DIR/volume.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh volume"
  updates=on
  icon.padding_left=10
  label.padding_right=5
)

backlight=(
  script="$PLUGIN_DIR/backlight.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh brightness"
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

cava=(
  update_freq=0
  script="$PLUGIN_DIR/cava.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh cava"
  label.drawing=on
  label.font="Hack Nerd Font Mono:Regular:13.0"
  icon.drawing=off
  label="cava"
  label.padding_left=4
  label.padding_right=10
  popup.align=right
)

memory=(
  icon.padding_left=15
  script="$PLUGIN_DIR/memory.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh memory"
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
  icon=$CPU_ICON
  icon.padding_left=15
  script="$PLUGIN_DIR/cpu.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh cpu"
  label.padding_left=10
  label.padding_right=15
  update_freq=4
  popup.align=right
)

apple=(
  script="$PLUGIN_DIR/apple.sh"
  click_script="$PLUGIN_DIR/open_menubar_items.sh apple"
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

$SKETCHYBAR_EXEC --bar "${bar[@]}"

## Adding sketchybar Items:
# Left Items
$SKETCHYBAR_EXEC --add item apple left \
  --set apple "${apple[@]}" \
  --subscribe apple mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 

# $SKETCHYBAR_EXEC --add space space left \
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
  $SKETCHYBAR_EXEC --add space space."$sid" left --set space."$sid" "${space[@]}" ignore_association=on 
  $SKETCHYBAR_EXEC --subscribe space."$sid" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
done

$SKETCHYBAR_EXEC --add item separator_left left \
  --set separator_left \
    icon= \
    padding_left=8 \
    label.drawing=off

$SKETCHYBAR_EXEC --add item front_app left \
  --set front_app \
    script="$PLUGIN_DIR/front_app.sh" \
    click_script="if [ \"$($yabai -m query --windows --window | $jq -r '.app')\" = \"Alacritty\" ]; then $osascript -e 'tell application \"System Events\" to keystroke \"w\" using {command down}'; else $yabai -m window --close; fi" \
    icon.drawing=on \
    label.padding_left=8 \
    label.padding_right=10 \
    updates=on \
  --subscribe front_app front_app_switched window_focus windows_on_spaces title_change mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 

$SKETCHYBAR_EXEC --add item active_app left \
    --set active_app "${active_app[@]}"

$SKETCHYBAR_EXEC --add item fullscreen_locker left \
  --set fullscreen_locker \
    updates=on \
    icon.drawing=off \
    label.drawing=off \
    update_freq=1 \
    script="$PLUGIN_DIR/fullscreen_lock.sh"
# Center Items
$SKETCHYBAR_EXEC --add item volume center \
  --set volume "${volume[@]}" \
  --subscribe volume volume_change mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global mouse.scrolled

$SKETCHYBAR_EXEC --add item backlight center \
  --set backlight "${backlight[@]}" \
  --subscribe backlight brightness_change mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global mouse.scrolled

$SKETCHYBAR_EXEC --add item nightlight center \
  --set nightlight "${nightlight[@]}" \
  --subscribe nightlight brightness_change mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global mouse.scrolled

$SKETCHYBAR_EXEC --add item datetime center \
  --set datetime "${datetime[@]}" \
  --subscribe datetime system_woke mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global mouse.scrolled

$SKETCHYBAR_EXEC --add item cava center \
  --set cava "${cava[@]}" \
  --subscribe cava volume_change spotify_change mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global mouse.scrolled
$SKETCHYBAR_EXEC \
  --add item spotify center \
  --set spotify "${spotify[@]}" \
  --subscribe spotify mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
# Right Items
$SKETCHYBAR_EXEC --add item memory right \
  --set memory "${memory[@]}" \
  --subscribe memory mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
$SKETCHYBAR_EXEC --add item cpu right \
  --set cpu "${cpu[@]}" \
  --subscribe cpu mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
$SKETCHYBAR_EXEC  --add item separator_right right \
  --set separator_right "${separator_right[@]}" \
    icon= \
    padding_right=0 \
    label.drawing=off 
$SKETCHYBAR_EXEC --add item battery right \
  --set battery "${battery[@]}" \
  --subscribe battery power_source_change system_woke mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
$SKETCHYBAR_EXEC --add item bluetooth right \
  --set bluetooth "${bluetooth[@]}" \
  --subscribe bluetooth system_woke mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 
$SKETCHYBAR_EXEC --add item wifi right \
  --set wifi "${wifi[@]}" \
  --subscribe wifi system_woke mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global 

brackets=(
  background.color=$base00
  background.height=25
  background.corner_radius=20
  background.border_color=$base07
  background.border_width=1
)

# Define the alias_position for alias items
alias_position="right"  # You can change this to "center", "left", or any custom alias_position

alias_style=(
  alias.color=$base05
  alias.scale=0.7
  padding_left=0
  padding_right=0
  alias.update_freq=1
)

# Add alias items with click actions
$SKETCHYBAR_EXEC --add alias "Control Center,BentoBox" $alias_position
$SKETCHYBAR_EXEC --set "Control Center,BentoBox" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh controlcenter \$BUTTON" \
    --subscribe "Control Center,BentoBox" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,Battery" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,Battery" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh battery" \
#     --subscribe "Control Center,Battery" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,Bluetooth" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,Bluetooth" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh bluetooth" \
#     --subscribe "Control Center,Bluetooth" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,WiFi" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,WiFi" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh wifi" \
#     --subscribe "Control Center,WiFi" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "Control Center,UserSwitcher" $alias_position
$SKETCHYBAR_EXEC --set "Control Center,UserSwitcher" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh userswitcher" \
    --subscribe "Control Center,UserSwitcher" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "macOS InstantView,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "macOS InstantView,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh macosinstantview \$BUTTON" \
    --subscribe "macOS InstantView,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "Karabiner-Menu,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "Karabiner-Menu,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh karabiner-menu \$BUTTON" \
    --subscribe "Karabiner-Menu,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "Background Music,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "Background Music,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh backgroundmusic \$BUTTON" \
    --subscribe "Background Music,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "Flameshot,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "Flameshot,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh flameshot \$BUTTON" \
    --subscribe "Flameshot,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "KDE Connect,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "KDE Connect,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh kde-connect \$BUTTON" \
    --subscribe "KDE Connect,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

$SKETCHYBAR_EXEC --add alias "MacForgeHelper,Item-0" $alias_position
$SKETCHYBAR_EXEC --set "MacForgeHelper,Item-0" "${alias_style[@]}" \
    click_script="$PLUGIN_DIR/open_menubar_items.sh macforge-helper \$BUTTON" \
    --subscribe "MacForgeHelper,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,Airdrop" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,Airdrop" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh airdrop" \
#     --subscribe "Control Center,Airdrop" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,Clock" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,Clock" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_clock.scpt" \
#     --subscribe "Control Center,Clock" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Spotlight,Item-0" $alias_position
# $SKETCHYBAR_EXEC --set "Spotlight,Item-0" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_spotlight.scpt" \
#     --subscribe "Spotlight,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "AltTab,Item-0" $alias_position
# $SKETCHYBAR_EXEC --set "AltTab,Item-0" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh alttab" \
#     --subscribe "AltTab,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "UnnaturalScrollWheels,Item-0" $alias_position
# $SKETCHYBAR_EXEC --set "UnnaturalScrollWheels,Item-0" "${alias_style[@]}" \
#     click_script="$PLUGIN_DIR/open_menubar_items.sh unnaturalscrollwheels" \
#     --subscribe "UnnaturalScrollWheels,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Hidden Bar,hiddenbar_expandcollapse" $alias_position
# $SKETCHYBAR_EXEC --set "Hidden Bar,hiddenbar_expandcollapse" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_hiddenbar_expandcollapse.scpt" \
#     --subscribe "Hidden Bar,hiddenbar_expandcollapse" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Control Center,AudioVideoModule" $alias_position
# $SKETCHYBAR_EXEC --set "Control Center,AudioVideoModule" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_audiovideomodule.scpt" \
#     --subscribe "Control Center,AudioVideoModule" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "TextInputMenuAgent,Item-0" $alias_position
# $SKETCHYBAR_EXEC --set "TextInputMenuAgent,Item-0" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_textinputmenuagent.scpt" \
#     --subscribe "TextInputMenuAgent,Item-0" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Hidden Bar,hiddenbar_separate" $alias_position
# $SKETCHYBAR_EXEC --set "Hidden Bar,hiddenbar_separate" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_hiddenbar_separate.scpt" \
#     --subscribe "Hidden Bar,hiddenbar_separate" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add alias "Hidden Bar,hiddenbar_terminate" $alias_position
# $SKETCHYBAR_EXEC --set "Hidden Bar,hiddenbar_terminate" "${alias_style[@]}" \
#     click_script="osascript /path/to/click_hiddenbar_terminate.scpt" \
#     --subscribe "Hidden Bar,hiddenbar_terminate" mouse.clicked mouse.entered mouse.entered.global mouse.exited mouse.exited.global

# $SKETCHYBAR_EXEC --add item rbracket_padding_left right --set rbracket_padding_left icon.padding_right=4 icon.padding_left=4 icon="" # because it is leftmost of the bracket.

# https://felixkratz.github.io/SketchyBar/config/components#item-bracket----group-items-in-eg-colored-sections
$SKETCHYBAR_EXEC --add bracket lbracket apple space '/space\..*/' separator_left front_app left \
  --set lbracket "${brackets[@]}"
$SKETCHYBAR_EXEC --add bracket cbracket volume backlight nightlight datetime cava spotify center \
  --set cbracket "${brackets[@]}" 
$SKETCHYBAR_EXEC --add bracket rbracket "Control Center,BentoBox" \
  "macOS InstantView,Item-0" "Karabiner-Menu,Item-0" "Control Center,UserSwitcher" "MacForgeHelper,Item-0" "Background Music,Item-0" "Flameshot,Item-0" \
  "KDE Connect,Item-0" wifi battery bluetooth separator_right memory cpu right \
  --set rbracket "${brackets[@]}"

#initialize states
printf "on\n" > "/tmp/sketchybar_state"
printf "on\n" > "/tmp/gaps_state"
dismiss-notifications # not working?
if [ -f "$HOME/.config/sketchybar/calendar_init_flag" ]; then
    rm "$HOME/.config/sketchybar/calendar_init_flag" # remove calendar flag at sketchybar launch if it exists
fi

$SKETCHYBAR_EXEC --update