{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
  nixy_colors = pkgs.writeShellScript "nixy-colors" ''
    export PURPLE="0xff${colors.base0C}" # Border color.
    export GREY="0xff${colors.base0C}"  # idk what this is for
    export TRANSPARENT=0x00000000
    export WHITE="0xff${colors.base05}"
    export BLUE="0xE6${colors.base0D}"  # Changes background of drop-down windows 
    export MAGENTA="0xff${colors.base0E}" # Changed border color? NO
    export ORANGE=0xff${colors.base0A}
    export TEMPUS="0xE6${colors.base02}" # backgrounds of RAM, spotify, apple logo, time and date
    export STATUS="0xE6${colors.base00}" #BACKGROUND of bar. make same as alacritty.
    export SPACEBG=0xFF808080 #Didn't change much?
    export MIDNIGHT="0xE6${colors.base03}" # Only worked on the mail icon?
  '';
in
{
  # ALL MUST BE MARKED AS EXECUTABLE!
  xdg.configFile."sketchybar/sketchybarrc".source = ./sketchybarrc.sh;
  xdg.configFile."sketchybar/icons.sh".source = ./icons.sh;
  xdg.configFile."sketchybar/colors.sh".source = nixy_colors;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".source = ./plugins/sway_spaces.sh;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".source = ./plugins/add_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".source = ./plugins/print_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/yabai_i3_switch.sh".source = ./plugins/yabai_i3_switch.sh;
  xdg.configFile."sketchybar/plugins/apple.sh".source = ./plugins/apple.sh;
  xdg.configFile."sketchybar/plugins/battery.sh".source = ./plugins/battery.sh;
  xdg.configFile."sketchybar/plugins/cpu.sh".source = ./plugins/cpu.sh;
  xdg.configFile."sketchybar/plugins/datetime.sh".source = ./plugins/datetime.sh;
  xdg.configFile."sketchybar/plugins/mail.sh".source = ./plugins/mail.sh;
  xdg.configFile."sketchybar/plugins/ram.sh".source = ./plugins/ram.sh;
  xdg.configFile."sketchybar/plugins/space.sh".source = ./plugins/space.sh;
  xdg.configFile."sketchybar/plugins/front_app.sh".source = ./plugins/front_app.sh;
  xdg.configFile."sketchybar/plugins/speed.sh".source = ./plugins/speed.sh;
  xdg.configFile."sketchybar/plugins/spotify.sh".source = ./plugins/spotify.sh;
  xdg.configFile."sketchybar/plugins/cava.sh".source = ./plugins/cava.sh;
  xdg.configFile."sketchybar/plugins/cava.conf".source = ./plugins/cava.conf;
  xdg.configFile."sketchybar/plugins/time.sh".source = ./plugins/time.sh;
  xdg.configFile."sketchybar/plugins/volume.sh".source = ./plugins/volume.sh;
  xdg.configFile."sketchybar/plugins/wifi.sh".source = ./plugins/wifi.sh;
  # Specify executable for each file
  xdg.configFile."sketchybar/sketchybarrc".executable = true;
  xdg.configFile."sketchybar/icons.sh".executable = true;
  xdg.configFile."sketchybar/colors.sh".executable = true;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".executable = true;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/yabai_i3_switch.sh".executable = true;
  xdg.configFile."sketchybar/plugins/apple.sh".executable = true;
  xdg.configFile."sketchybar/plugins/battery.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cpu.sh".executable = true;
  xdg.configFile."sketchybar/plugins/datetime.sh".executable = true;
  xdg.configFile."sketchybar/plugins/mail.sh".executable = true;
  xdg.configFile."sketchybar/plugins/ram.sh".executable = true;
  xdg.configFile."sketchybar/plugins/space.sh".executable = true;
  xdg.configFile."sketchybar/plugins/front_app.sh".executable = true;
  xdg.configFile."sketchybar/plugins/speed.sh".executable = true;
  xdg.configFile."sketchybar/plugins/spotify.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.conf".executable = true;
  xdg.configFile."sketchybar/plugins/time.sh".executable = true;
  xdg.configFile."sketchybar/plugins/volume.sh".executable = true;
  xdg.configFile."sketchybar/plugins/wifi.sh".executable = true;
}
