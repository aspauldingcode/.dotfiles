
#CHECK HERE TO IMPLEMENT FULLY:
#https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-5771466
#It replaces all the colors on the fly without needing to restart sketchybar, makes use of the nice animation feature as well..

#!/bin/zsh

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source $HOME/.config/sketchybar/constants.sh
LIGHT_THEME_COLORS=(${LIGHT_THEME_COLORS:l})
DARK_THEME_COLORS=(${DARK_THEME_COLORS:l})

echo "Switching sketchybar to $1 theme.."

for color in $LIGHT_THEME_COLORS; do
  key_value=($(echo $color | pcregrep -o1 -o2 --om-separator=" " "(\w*)=(0[xX][0-9a-fA-F]+)"))

  light_color=${key_value[2]}
  dark_color=$(echo $DARK_THEME_COLORS | pcregrep -o1 "${key_value[1]}=(0[xX][0-9a-fA-F]+)")

  [[ $1 = 'light' ]] && { source_colors+=($dark_color ); sub_map+=("s/$dark_color/$light_color/g;") } \
                     || { source_colors+=($light_color); sub_map+=("s/$light_color/$dark_color/g;") }
done

updated_item_properties() {
  $SKETCHYBAR_EXEC --query $1 |
    jq -r 'leaf_paths as $path | ($path | join(".")) + "=" + (getpath($path)|tostring) | select(contains("color"))' |
    grep -E "$(echo $source_colors | tr ' ' '|')" |
    sed -e "${sub_map}s/geometry.//g;" |
    tr ' \n' ' '
}

$SKETCHYBAR_EXEC --animate linear 10 --bar $(updated_item_properties bar) &
$SKETCHYBAR_EXEC --query bar |
  jq -r ".items[]" |
  while read -r item_name; do
    $SKETCHYBAR_EXEC --animate linear 10 --set $item_name $(updated_item_properties $item_name) &
  done






  RELEVENT PART OF MY constants.sh:

  LIGHT_THEME_COLORS=(
  WHITE_FADED_PLUS='0x55575279'
  WHITE_FADED='0x77575279'
  WHITE='0xff575279'
  BACKGROUND='0xfffaf4ed'
)
DARK_THEME_COLORS=(
  CYAN='0xff88C0D0'
  BLUE='0xff81A1C1'
  MAGENTA='0xffB48EAD'
  ORANGE='0xffffa500'
  GREEN='0xffA3BE8C'
  YELLOW='0xffEBCB8B'
  RED='0xffBF616A'
  WHITE='0xffd8dee9'
  WHITE_FADED='0x55ffffff'
  WHITE_FADED_PLUS='0x11ffffff'
  BACKGROUND='0xff2E3440'
  TRANSPARENT='0x00000000'
)

eval $DARK_THEME_COLORS
grep -q lighttheme ~/.config/kitty/theme.conf && eval $LIGHT_THEME_COLORS



Toggle_theme.sh:

#!/bin/zsh

# vim is triggered by /theme.conf
grep -q darktheme ~/.config/kitty/theme.conf && target="light" || target="dark"

# Set kitty theme and send refresh signal
echo "#${target}theme\ninclude ./${target}.conf" > ~/.config/kitty/theme.conf && pkill -USR1 kitty

# Switch wallpaper
cp ~/.config/wp/wp_${target}.png ~/.config/wp/wp.png && killall Dock &

# Change system dark mode
osascript -e "tell app \"System Events\" to tell appearance preferences to set dark mode to $target=dark" &

# Reload sketchybar theme
~/.config/sketchybar/reload_theme.sh $target &
