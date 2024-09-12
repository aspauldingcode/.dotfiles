# AUDIO VISUALIZER:
# https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-6224928

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

#kill cava if it is already running.
if pgrep cava > /dev/null; then
  pkill cava
fi

# open Background Music if it is not open.
if ! pgrep BackgroundMusic > /dev/null; then
  open -a "Background Music"
fi

cava -p $PLUGIN_DIR/cava.conf | sed -u 's/ //g; s/0/▁/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g; s/8/█/g' | while read line; do

cava -p $PLUGIN_DIR/cava.conf | sed -u 's/ //g; s/0/▁/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g; s/8/█/g' | while read line; do
  sketchybar --set cava label=$line label.font="Droid Sans Mono for Powerline:Regular:12.0" #FIXME: change it so this font fixes spacing issues between bars
done

# Handle mouse events for hover status
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
    # clicked effect
    sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
esac
