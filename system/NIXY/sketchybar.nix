
{ config, lib, pkgs, ... }:

{
  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
    config = ''
      # SketchyBar configuration

      # Basic configuration
      #sketchybar --bar height=27
      sketchybar --update

      # Plugin directory
      PLUGIN_DIR="$CONFIG_DIR/plugins"

      # Bar Appearance
      sketchybar --bar height=32
        blur_radius=30
        position=top
        sticky=off
        padding_left=10
        padding_right=10
        color=0x10282828

      # Changing Defaults
      sketchybar --default icon.font="Hack Nerd Font:Bold:17.0"
        icon.color=0xffffffff
        label.font="Hack Nerd Font:Bold:14.0"
        label.color=0xffffffff
        padding_left=5
        padding_right=5
        label.padding_left=4
        label.padding_right=4
        icon.padding_left=4
        icon.padding_right=4

      # Adding Mission Control Space Indicators
      SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

      for i in $SPACE_ICONS
      do
        sid=$(($i + 1))
        sketchybar --add space space.$sid left
          --set space.$sid space=$sid
          icon=$i
          background.color=0x10282828
          background.corner_radius=2
          background.height=20
          background.drawing=off
          label.drawing=off
          script="$PLUGIN_DIR/space.sh"
          click_script="yabai -m space --focus $sid"
      done

      # Adding Left Items
      sketchybar --add item space_separator left
        --set space_separator icon=
          padding_left=10
          padding_right=10
          label.drawing=off

      sketchybar --add item front_app left
        --set front_app script="$PLUGIN_DIR/front_app.sh"
          icon.drawing=off
        --subscribe front_app front_app_switched

      # Adding Right Items
      sketchybar --add item clock right
        --set clock update_freq=10
          icon=
          script="$PLUGIN_DIR/clock.sh"

      sketchybar --add item volume right
        --set volume script="$PLUGIN_DIR/volume.sh"
        --subscribe volume volume_change

      sketchybar --add item battery right
        --set battery script="$PLUGIN_DIR/battery.sh"
          update_freq=120
        --subscribe battery system_woke power_source_change

      # Finalizing Setup
      sketchybar --update
      echo "SketchyBar configuration loaded.."
    '';
  };
}
