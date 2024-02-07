# AUDIO VISUALIZER:
# https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-6224928

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

#FIXME: only run if it's not already there!!!
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Background Music.app/", hidden:false}'

while true
do
  cava -p $PLUGIN_DIR/cava.conf | sed -u 's/ //g; s/0/▁/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g; s/8/█/g' | while read line; do
    sketchybar --set cava label=$line label.font="DejaVu Mono:Book:12.0" #FIXME: change it so this font fixes spacing issues between bars
  done
  sleep 5
done
