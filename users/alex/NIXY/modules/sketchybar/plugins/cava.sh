# AUDIO VISUALIZER:
# https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-6224928

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

#FIXME: only run if it's not already there!!!
# osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Background Music.app/", hidden:false}'

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