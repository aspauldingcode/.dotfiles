{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
  nixy_colors = pkgs.writeShellScript "nixy-colors" ''
    export base00="0xff${colors.base00}"
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
  source_sketchybar = pkgs.writeShellScript "source_sketchybar" ''
    #!/bin/sh
    # SKETCHYBAR_EXEC=/Users/alex/sketchybar/bin/sketchybar
    SKETCHYBAR_EXEC="${pkgs.sketchybar}/bin/sketchybar"
    export SKETCHYBAR_EXEC
  '';
  brightness = pkgs.writeShellScript "brightness" ''
    #!/bin/sh

    # Function to press the brightness up key
    brightness_up() {
      osascript -e 'tell application "System Events" to key code 144'
    }

    # Function to press the brightness down key
    brightness_down() {
      osascript -e 'tell application "System Events" to key code 145'
    }

    # Adjust brightness based on the provided number of times
    brightness() {
      local times=$1

      if [[ $times -gt 0 ]]; then
        for ((i = 0; i < times; i++)); do
          brightness_up
        done
      elif [[ $times -lt 0 ]]; then
        for ((i = 0; i < -times; i++)); do
          brightness_down
        done
      fi
    }

    # Only run the brightness function if the script is executed directly
    if [[ "''${BASH_SOURCE[0]}" == "''${0}" ]]; then
      if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <number>"
        exit 1
      fi
      brightness "$1"
    fi
  '';
  detect_arch_and_source_homebrew_packages = pkgs.writeShellScript "detect_arch_and_source_homebrew_packages" ''
    #!/bin/sh

    systemType=$(uname -m)
    if [ "$systemType" = "arm64" ]; then
      homebrewPath="/opt/homebrew/bin"
    elif [ "$systemType" = "x86_64" ]; then
      homebrewPath="/usr/local/bin"
    else
      echo "Unsupported architecture: $systemType"
      exit 1
    fi

    # define software fullpaths
    yabai="${pkgs.yabai}/bin/yabai"
    jq="${pkgs.jq}/bin/jq"
    osascript="/usr/bin/osascript"
    gcal="${pkgs.gcal}/bin/gcal"
    toggle_sketchybar="${pkgs.sketchybar}/bin/toggle-sketchybar"
    nightlight="''${homebrewPath}/nightlight"
    desktoppr="/usr/local/bin/desktoppr"
    wallpaper="/Users/Shared/Wallpaper/wallpaper-nix-colors.png"
    blueutil="${pkgs.blueutil}/bin/blueutil"
    nowplaying_cli="${pkgs.nowplaying-cli}/bin/nowplaying-cli"
    cava="${pkgs.cava}/bin/cava"
    flameshot="${pkgs.flameshot}/bin/flameshot"
  '';
in
{
  # ALL MUST BE MARKED AS EXECUTABLE!
  xdg.configFile."sketchybar/sketchybarrc".source = ./sketchybarrc.sh;
  xdg.configFile."sketchybar/icons.sh".source = ./icons.sh;
  xdg.configFile."sketchybar/colors.sh".source = nixy_colors;
  xdg.configFile."sketchybar/brightness.sh".source = brightness;
  xdg.configFile."sketchybar/source_sketchybar.sh".source = source_sketchybar;
  xdg.configFile."sketchybar/plugins/detect_arch_and_source_homebrew_packages.sh".source =
    detect_arch_and_source_homebrew_packages;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".source = ./plugins/sway_spaces.sh;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".source =
    ./plugins/add_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".source =
    ./plugins/print_spaces_sketchybar.sh;
  xdg.configFile."sketchybar/plugins/fullscreen_lock.sh".source = ./plugins/fullscreen_lock.sh;
  xdg.configFile."sketchybar/plugins/apple.sh".source = ./plugins/apple.sh;
  xdg.configFile."sketchybar/plugins/battery.sh".source = ./plugins/battery.sh;
  xdg.configFile."sketchybar/plugins/bluetooth.sh".source = ./plugins/bluetooth.sh;
  xdg.configFile."sketchybar/plugins/cpu.sh".source = ./plugins/cpu.sh;
  xdg.configFile."sketchybar/plugins/datetime.sh".source = ./plugins/datetime.sh;
  xdg.configFile."sketchybar/plugins/memory.sh".source = ./plugins/memory.sh;
  xdg.configFile."sketchybar/plugins/space.sh".source = ./plugins/space.sh;
  xdg.configFile."sketchybar/plugins/front_app.sh".source = ./plugins/front_app.sh;
  xdg.configFile."sketchybar/plugins/spotify.sh".source = ./plugins/spotify.sh;
  xdg.configFile."sketchybar/plugins/cava.sh".source = ./plugins/cava.sh;
  xdg.configFile."sketchybar/plugins/cava.conf".source = ./plugins/cava.conf;
  xdg.configFile."sketchybar/plugins/volume.sh".source = ./plugins/volume.sh;
  xdg.configFile."sketchybar/plugins/backlight.sh".source = ./plugins/backlight.sh;
  xdg.configFile."sketchybar/plugins/wifi.sh".source = ./plugins/wifi.sh;
  xdg.configFile."sketchybar/plugins/open_menubar_items.sh".source = ./plugins/open_menubar_items.sh;
  xdg.configFile."sketchybar/plugins/nightlight.sh".source = ./plugins/nightlight.sh;
  xdg.configFile."sketchybar/plugins/media_control.sh".source = ./plugins/media_control.sh;
  xdg.configFile."sketchybar/plugins/fastfetch_config.jsonc".source =
    ./plugins/fastfetch_config.jsonc;

  # Specify executable for each file
  xdg.configFile."sketchybar/sketchybarrc".executable = true;
  xdg.configFile."sketchybar/icons.sh".executable = true;
  xdg.configFile."sketchybar/colors.sh".executable = true;
  xdg.configFile."sketchybar/brightness.sh".executable = true;
  xdg.configFile."sketchybar/plugins/detect_arch_and_source_homebrew_packages.sh".executable = true;
  xdg.configFile."sketchybar/plugins/sway_spaces.sh".executable = true;
  xdg.configFile."sketchybar/plugins/add_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/print_spaces_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/fullscreen_lock.sh".executable = true;
  xdg.configFile."sketchybar/plugins/apple.sh".executable = true;
  xdg.configFile."sketchybar/plugins/battery.sh".executable = true;
  xdg.configFile."sketchybar/plugins/bluetooth.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cpu.sh".executable = true;
  xdg.configFile."sketchybar/plugins/datetime.sh".executable = true;
  xdg.configFile."sketchybar/plugins/memory.sh".executable = true;
  xdg.configFile."sketchybar/plugins/space.sh".executable = true;
  xdg.configFile."sketchybar/plugins/front_app.sh".executable = true;
  xdg.configFile."sketchybar/plugins/spotify.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.conf".executable = true;
  xdg.configFile."sketchybar/plugins/volume.sh".executable = true;
  xdg.configFile."sketchybar/plugins/backlight.sh".executable = true;
  xdg.configFile."sketchybar/plugins/wifi.sh".executable = true;
  xdg.configFile."sketchybar/plugins/open_menubar_items.sh".executable = true;
  xdg.configFile."sketchybar/plugins/nightlight.sh".executable = true;
  xdg.configFile."sketchybar/plugins/media_control.sh".executable = true;
  xdg.configFile."sketchybar/source_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/fastfetch_config.jsonc".executable = true;
}
