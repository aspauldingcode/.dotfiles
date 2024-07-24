{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
  nixy_colors = pkgs.writeShellScript "nixy-colors" ''
    export base00="0xE6${colors.base00}"
    export base01="0xff${colors.base01}"
    export base02="0xE6${colors.base02}"
    export base03="0xE6${colors.base03}"
    export base04="0xff${colors.base04}"
    export base05="0xff${colors.base05}"
    export base06="0xff${colors.base06}"
    export base07="0xff${colors.base07}"
    export base08="0xff${colors.base08}"
    export base09="0xff${colors.base09}"
    export base0A="0xff${colors.base0A}"
    export base0B="0xff${colors.base0B}"
    export base0C="0xff${colors.base0C}"
    export base0D="0xE6${colors.base0D}"
    export base0E="0xff${colors.base0E}"
    export base0F="0xff${colors.base0F}"
    export TRANSPARENT=0x00000000
  '';
  start_programs_correctly = pkgs.writeShellScript "start_programs_correctly" ''
    start_programs_correctly() {
      ${pkgs.start_programs_correctly}/bin/start_programs_correctly
    }
    start_programs_correctly
  '';
  brightness = pkgs.writeShellScript "brightness" ''
    export brightness="${pkgs.brightness}/bin/brightness"
  '';
in
{
  # ALL MUST BE MARKED AS EXECUTABLE!
  xdg.configFile."sketchybar/sketchybarrc".source = ./sketchybarrc.sh;
  xdg.configFile."sketchybar/icons.sh".source = ./icons.sh;
  xdg.configFile."sketchybar/colors.sh".source = nixy_colors;
  xdg.configFile."sketchybar/start_programs_correctly.sh".source = start_programs_correctly;
  xdg.configFile."sketchybar/brightness.sh".source = brightness;
  xdg.configFile."sketchybar/plugins/detect_arch_and_source_homebrew_packages.sh".source = ./plugins/detect_arch_and_source_homebrew_packages.sh;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".source = ./plugins/sway_spaces.sh;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".source = ./plugins/add_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".source = ./plugins/print_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/yabai_i3_switch.sh".source = ./plugins/yabai_i3_switch.sh;
  xdg.configFile."sketchybar/plugins/fullscreen_lock.sh".source = ./plugins/fullscreen_lock.sh;
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
  xdg.configFile."sketchybar/plugins/volume.sh".source = ./plugins/volume.sh;
  xdg.configFile."sketchybar/plugins/backlight.sh".source = ./plugins/backlight.sh;
  xdg.configFile."sketchybar/plugins/wifi.sh".source = ./plugins/wifi.sh;
  xdg.configFile."sketchybar/plugins/open_menubar_items.sh".source = ./plugins/open_menubar_items.sh;
  xdg.configFile."sketchybar/plugins/nightlight.sh".source = ./plugins/nightlight.sh;

  # Specify executable for each file
  xdg.configFile."sketchybar/sketchybarrc".executable = true;
  xdg.configFile."sketchybar/icons.sh".executable = true;
  xdg.configFile."sketchybar/colors.sh".executable = true;
  xdg.configFile."sketchybar/start_programs_correctly.sh".executable = true;
  xdg.configFile."sketchybar/brightness.sh".executable = true;
  xdg.configFile."sketchybar/plugins/detect_arch_and_source_homebrew_packages.sh".executable = true;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".executable = true;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/yabai_i3_switch.sh".executable = true;
  xdg.configFile."sketchybar/plugins/fullscreen_lock.sh".executable = true;
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
  xdg.configFile."sketchybar/plugins/volume.sh".executable = true;
  xdg.configFile."sketchybar/plugins/backlight.sh".executable = true;
  xdg.configFile."sketchybar/plugins/wifi.sh".executable = true;
  xdg.configFile."sketchybar/plugins/open_menubar_items.sh".executable = true;
  xdg.configFile."sketchybar/plugins/nightlight.sh".executable = true;
}
