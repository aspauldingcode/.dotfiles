{ config, pkgs, unstable, ... }:

# config for yabai, skhd, sketchybar, and borders.
let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath = if systemType == "aarch64-darwin" then "/opt/homebrew/bin" else if systemType == "x86_64-darwin" then "/usr/local/bin" else throw "Homebrew Unsupported architecture: ${systemType}";
  yabai = "${pkgs.yabai}/bin/yabai";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  borders = "${pkgs.jankyborders}/bin/borders";
  i3-msg = "${homebrewPath}/i3-msg";
  alacritty = "${homebrewPath}/alacritty";
  firefox = "${homebrewPath}/firefox";
  app_menu = "/Applications/unmenu.app/Contents/MacOS/unmenu";
  jq = "${pkgs.jq}/bin/jq";
  inherit (config.colorScheme) palette;

  desktoppr = "/usr/local/bin/desktoppr";
  wallpaper = "/Users/Shared/Wallpaper/wallpaper-nix-colors.png";
in
{
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    package = pkgs.callPackage ./../../customDerivations/yabai.nix { };
    config = {
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "on";
      window_shadow = "off";
      window_opacity = "on";
      window_opacity_duration = 0.1;
      active_window_opacity = 1.0;
      insert_feedback_color = "0xff${palette.base07}";
      layout = "bsp";
      auto_balance = "off";
      split_ratio = 0.50;
      window_placement = "second_child";
      display_arrangement_order = "horizontal";
      window_zoom_persist = "on";
      window_origin_display = "cursor";
      top_padding = 15;
      bottom_padding = 15;
      left_padding = 15;
      right_padding = 15;
      window_gap = 15;
      external_bar = "all:50:0";
      menubar_opacity = 1.0;
    };
    extraConfig = ''
      # set wallpaper first
      ${desktoppr} ${wallpaper}

      # unsure if needed... 
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

      yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus &> /dev/null"
      yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces &> /dev/null"
      yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces &> /dev/null"
      yabai -m signal --add event=window_title_changed action="sketchybar --trigger title_change &> /dev/null"
      yabai -m signal --add event=space_changed action="yabai -m window --focus \$(yabai -m query --windows --space | ${jq} .[0].id)"
      yabai -m signal --add event=display_changed action="yabai -m window --focus \$(yabai -m query --windows --space | ${jq} .[0].id)"
      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^System Information$" manage=off
      yabai -m rule --add app="^System Preferences$" manage=off
      yabai -m rule --add title=".*Preferences$" manage=off
      yabai -m rule --add title=".*Settings$" manage=off
      yabai -m rule --add app='^zoom\.us$' manage=off
      yabai -m rule --add app='^Finder$' manage=off
      yabai -m rule --add title="^XQuartz$" manage=off
      yabai -m rule --add app='^XQuartz$' manage=off
      yabai -m rule --add app='^X11\.bin$' manage=off
      yabai -m rule --add app='^X11$' manage=off
      yabai -m rule --add app='^Archive Utility$' manage=off
      yabai -m rule --add app='^Display Calibrator$' manage=off
      yabai -m rule --add app='^Installer$' manage=off
      yabai -m rule --add app='^Karabiner-EventViewer$' manage=off
      yabai -m rule --add app='^Karabiner-Elements$' manage=off
      yabai -m rule --add app='MacForge' manage=off
      yabai -m rule --add app='^macOS InstantView$' manage=off
      yabai -m rule --add app='^Dock$' manage=off
      yabai -m rule --add app='Brave Browser' layer=below
      yabai -m rule --add app='Sketchybar' layer=below
      yabai -m rule --add app='borders' layer=below
      ${borders}
      
      mkdir -p ~/.config/yabai/cache/
      touch ~/.config/yabai/cache/lockfile
      YABAI_CACHE=~/.config/yabai/cache/
      function _update_cache {
        local lockfile current
        lockfile="$YABAI_CACHE/lockfile"
        current="$(who -b)"
        if [[ ! -e "$lockfile" ]]; then
          print -r -- "$current" >"$lockfile"
        elif [[ "$current" != "$(cat "$lockfile")" ]]; then
          rm -rf "$YABAI_CACHE"
          mkdir -p "$YABAI_CACHE"
          print -r -- "$current" >"$lockfile"
        fi
      }
      _update_cache

      echo "yabai configuration loaded.."
    '';
  };
}
