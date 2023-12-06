#!/bin/bash

# Sourcing color and icon configurations
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

LINE_1=$(cal -h | sed -n '1p')
LINE_2=$(cal -h | sed -n '2p')
LINE_3=$(cal -h | sed -n '3p')
LINE_4=$(cal -h | sed -n '4p')
LINE_5=$(cal -h | sed -n '5p')
LINE_6=$(cal -h | sed -n '6p')
LINE_7=$(cal -h | sed -n '7p')
LINE_8=$(cal -h | sed -n '8p')

function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d   %r')"
  sketchybar --set $NAME icon=$TIME
}

# spotify_cover=(
#   label.drawing=off
#   icon.drawing=off
#   padding_left=12
#   padding_right=10
#   background.image.scale=0.13
#   background.image.drawing=on
#   background.drawing=on
#   background.image="/tmp/cover.jpg"
# )
#
# sketchybar --add item datetime.cover popup.datetime \
#   --set datetime.cover "${spotify_cover[@]}"

row_1=(
  label=$LINE_1
  label.font="JetBrains Mono:Bold:15.0"
  padding_left=10
  padding_right=10
  icon.drawing=off
  #label.padding_right=10
  width=0
  y_offset=56
)
sketchybar --add item datetime.popup.title popup.datetime \
  --set datetime.popup.title "${row_1[@]}" \

row_2=(
  label=$LINE_2
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=40
)
sketchybar --add item datetime.popup.cal_2 popup.datetime \
  --set datetime.popup.cal_2 "${row_2[@]}" 

row_3=(
  label=$LINE_3
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=24
)
sketchybar --add item datetime.popup.cal_3 popup.datetime \
  --set datetime.popup.cal_3 "${row_3[@]}" \

row_4=(
  label=$LINE_4
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=8
)
sketchybar --add item datetime.popup.cal_4 popup.datetime \
  --set datetime.popup.cal_4 "${row_4[@]}" \

row_5=(
  label=$LINE_5
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-8
)
sketchybar --add item datetime.popup.cal_5 popup.datetime \
  --set datetime.popup.cal_5 "${row_5[@]}" \

row_6=(
  label=$LINE_6
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-24
)
sketchybar --add item datetime.popup.cal_6 popup.datetime \
  --set datetime.popup.cal_6 "${row_6[@]}" \

row_7=(
  label=$LINE_7
  label.font="JetBrains Mono:Regular:12.0"
  width=150
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-40
)
sketchybar --add item datetime.popup.cal_7 popup.datetime \
  --set datetime.popup.cal_7 "${row_7[@]}" \

row_8=(
  label=$LINE_8
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-56
  background.padding_right=160
)
sketchybar --add item datetime.popup.cal_8 popup.datetime \
  --set datetime.popup.cal_8 "${row_8[@]}" \

# Main execution
set_date_and_time
