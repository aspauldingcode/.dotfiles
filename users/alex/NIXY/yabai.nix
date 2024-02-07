{ config, pkgs, lib, ... }: 

{
  home.file.yabai = {
    executable = true;
    target = ".config/yabai/yabairc";
    text = let inherit (config.colorScheme) colors; in ''
      #!/usr/bin/env sh

      # update_sudoers() {
      #   YABAI_PATH=$(which yabai)
      #   USERNAME=$(whoami)
      #   YABAI_HASH=$(shasum -a 256 $YABAI_PATH | awk '{print $1}')
      #   # Update the sudoers file
      #   echo "$USERNAME ALL=(root) NOPASSWD: sha256:$YABAI_HASH $YABAI_PATH --load-sa" | sudo tee -a /etc/sudoers
      # }
      #
      # update_sudoers()

      # load scripting addition
      sudo yabai --load-sa
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

      # bar configuration
      yabai -m config external_bar all:45:0
      yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
      yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
      yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"

      # move/resize windows with mouse
      yabai -m config mouse_modifier              alt
      yabai -m config mouse_action1               move
      yabai -m config mouse_action2               resize
      yabai -m config mouse_drop_action           swap
      yabai -m config focus_follows_mouse         autofocus
      yabai -m config mouse_follows_focus         off #FIXME: configure apps so I can turn this on.

      #UPGRADED to Sonoma. JankyBorders installed
      borders active_color=0xff"${colors.base0C}" inactive_color=0xff"${colors.base03}" width=5.0 &

      # window appearance
      yabai -m config window_shadow               float
      yabai -m config window_opacity              on
      yabai -m config window_opacity_duration     0.1
      yabai -m config window_animation_duration	  0.35
      yabai -m config window_opacity_duration	  0.35
      yabai -m config normal_window_opacity	  0.95
      yabai -m config active_window_opacity	  1.0
      
      # layout
      yabai -m config layout                      float # bsp
      yabai -m config auto_balance                off
      yabai -m config split_ratio                 0.50
      yabai -m config window_placement            second_child
      yabai -m config window_origin_display       default

      # floating windows are always on top
      # when enabling this option, overlays in chrome are hidden
      # this affects popups like site search or bitwarden extension
      # yabai -m config window_topmost off

      # gaps
      yabai -m config top_padding     15
      yabai -m config bottom_padding  15
      yabai -m config left_padding    15
      yabai -m config right_padding   15
      yabai -m config window_gap      15

      # rules
      yabai -m rule --add app="^System Settings$"     manage=off
      yabai -m rule --add app="^System Information$"  manage=off
      yabai -m rule --add app="^System Preferences$"  manage=off
      yabai -m rule --add title="Preferences$"        manage=off
      yabai -m rule --add title="Settings$"           manage=off
      yabai -m rule --add app='System Settings'       manage=off
      yabai -m rule --add app='System Information'    manage=off
      yabai -m rule --add app='zoom.us'               manage=off
      yabai -m rule --add app='Finder'                manage=off
      yabai -m rule --add app='Archive Utility'       manage=off
      yabai -m rule --add app='Display Calibrator'    manage=off
      yabai -m rule --add app='Installer'             manage=off
      yabai -m rule --add app='Karabiner-EventViewer' manage=off
      yabai -m rule --add app='Karabiner-Elements'    manage=off
      # yabai -m rule --add app='Alacritty'             layer=above
      yabai -m rule --add app='Brave Browser'         layer=below
      yabai -m rule --add app='Sketchybar'            layer=below
      yabai -m rule --add app='borders'               layer=below

      # # workspace management
      # yabai -m space 1  --label www
      # yabai -m space 2  --label code
      # yabai -m space 3  --label music
      # yabai -m space 4  --label chat
      # yabai -m space 5  --label todo
      # yabai -m space 6  --label voice
      # yabai -m space 7  --label seven
      # yabai -m space 8  --label eight
      # yabai -m space 9  --label nine
      # yabai -m space 10 --label ten
      #
      # # assign apps to spaces      
      # yabai -m rule --add app="Brave Browser"       space=www
      # yabai -m rule --add app="Google Chrome"       space=www
      # yabai -m rule --add app="Vivaldi"             space=www
      # yabai -m rule --add app="Arc"                 space=www
      #
      # yabai -m rule --add app="Alacritty"           space=code
      # yabai -m rule --add app="Terminal"            space=code
      # yabai -m rule --add app="Code"                space=code
      #
      # yabai -m rule --add app="Spotify"             space=music
      #
      # yabai -m rule --add app="Beeper"              space=chat
      # yabai -m rule --add app="Element"             space=chat
      # yabai -m rule --add app="Messages"            space=chat
      # yabai -m rule --add app="Slack"               space=chat
      # yabai -m rule --add app="Signal"              space=chat
      #
      # yabai -m rule --add app="Todoist"             space=todo
      #      # yabai -m rule --add app="Discord"             space=voice
      # yabai -m rule --add app="Mumble"              space=voice
      #
      # yabai -m rule --add app="Microsoft Teams"     space=nine

      echo "yabai configuration loaded.."

    '';
  };

  home.file.skhd = 
  # let
  #   toggle-sketchybar = pkgs.writeShellScriptBin "toggle-sketchybar" ''
  #  toggle_sketchybar() {
  #       local hidden_status=$(sketchybar --query bar | jq -r '.hidden')
  #
  #       if [ "$hidden_status" == "off" ]; then
  #           STATE="on"
  #           sketchybar --bar hidden=on
  #       else
  #           STATE="off"
  #           sketchybar --bar hidden=off
  #       fi
  #   }
  #
  #   # Example usage
  #   toggle_sketchybar
  #   '';
  # in  

  # let 
  #   toggle-layer-alacritty = pkgs.writeShellScriptBin "toggle-layer-alacritty" ''
  #
  #   check_focus_and_app() {
  #   # Run yabai command and store JSON output
  #   yabai_output=$(yabai -m query --windows --window)
  #
  #   # Extract the value of "has-focus" and "app" using jq
  #   has_focus=$(echo "$yabai_output" | jq -r '.["has-focus"]')
  #   app_name=$(echo "$yabai_output" | jq -r '.app')
  #
  #   # Check if "has-focus" is true and app name is "Alacritty"
  #   if [ "$has_focus" = "true" ] && [ "$app_name" = "Alacritty" ]; then
  #       echo "The focused window is true and the app name is Alacritty."
  #       # Add your custom actions here if needed
  #       say true
  #   else
  #       echo "Either the focused window is not true or the app name is not Alacritty."
  #       # Add alternative actions if needed
  #       say false
  #   fi
  #   }
  #
  #   # Call the function
  #   check_focus_and_app
  #   '';
  # in
  {
    executable = true;
    target = ".config/skhd/skhdrc";
    text = let 
      # toggle-sketchybar = "/Users/alex/.nix-profile/bin/toggle-sketchybar";
      yabai = "/opt/homebrew/bin/yabai";
      left =  "h";
      down =  "j";
      up =    "k";
      right = "l";
      mod1 =  "alt";
      mod4 =  "cmd";
      mod5 =  "ctrl";
      modifier =   mod1; 
    in
      ''
        # alt + a / u / o / s are blocked due to umlaute
        
        # Launch shortcuts
        ${modifier} - return :                open -na /opt/homebrew/bin/alacritty #FIXME: Alacritty is broken atm. Using homebrew. 
        # ${modifier} - return :              alacritty
        ${modifier} - d :                     open -a dmenu-mac
        ${mod1} + ${mod5} - space :           open -na "Brave Browser"
        ${mod4} + ${mod5} - 0x33 :            sudo reboot # using cmd ctrl backspace
        ${mod4} + ${mod5} + shift - 0x33 :    sudo shutdown -h now # using cmd ctrl backspace
        ${mod4} + ${mod5} - delete :          sudo reboot
        ${mod4} + ${mod5} + shift - delete :  sudo shutdown -h now
        ${modifier} + shift - q :             ${yabai} -m window --close
	      ${modifier} - f :                     ${yabai} -m window --toggle zoom-fullscreen 
        ${modifier} + shift - f :             ${yabai} -m window --toggle native-fullscreen
        
        #ctrl + shift - f :               toggle-layer-alacritty FIXME: BROKEN
        #AsF - Try making this a system script isntead of user script binary!
        
        # Move focus to next/prev workspace
        ${mod1} + ${mod4} - ${left} :   ${yabai} -m space --focus prev
        ${mod1} + ${mod4} - ${down} :   ${yabai} -m space --focus prev
        ${mod1} + ${mod4} - ${up} :     ${yabai} -m space --focus next
        ${mod1} + ${mod4} - ${right} :  ${yabai} -m space --focus next
        ${mod1} + ${mod4} - left :      ${yabai} -m space --focus prev
        ${mod1} + ${mod4} - down :      ${yabai} -m space --focus prev
        ${mod1} + ${mod4} - up :        ${yabai} -m space --focus next
        ${mod1} + ${mod4} - right :     ${yabai} -m space --focus next

        # move focused window to workspace n & follow focus
        ${modifier} + shift - 1 : ${yabai} -m window --space 1;  ${yabai} -m space --focus 1
        ${modifier} + shift - 2 : ${yabai} -m window --space 2;  ${yabai} -m space --focus 2
        ${modifier} + shift - 3 : ${yabai} -m window --space 3;  ${yabai} -m space --focus 3
        ${modifier} + shift - 4 : ${yabai} -m window --space 4;  ${yabai} -m space --focus 4
        ${modifier} + shift - 5 : ${yabai} -m window --space 5;  ${yabai} -m space --focus 5
        ${modifier} + shift - 6 : ${yabai} -m window --space 6;  ${yabai} -m space --focus 6
        ${modifier} + shift - 7 : ${yabai} -m window --space 7;  ${yabai} -m space --focus 7
        ${modifier} + shift - 8 : ${yabai} -m window --space 8;  ${yabai} -m space --focus 8
        ${modifier} + shift - 9 : ${yabai} -m window --space 9;  ${yabai} -m space --focus 9
        ${modifier} + shift - 0 : ${yabai} -m window --space 10; ${yabai} -m space --focus 10
        
        # move focused space to workspace n
        ${modifier} - 1 : ${yabai} -m space --focus 1
        ${modifier} - 2 : ${yabai} -m space --focus 2
        ${modifier} - 3 : ${yabai} -m space --focus 3
        ${modifier} - 4 : ${yabai} -m space --focus 4
        ${modifier} - 5 : ${yabai} -m space --focus 5
        ${modifier} - 6 : ${yabai} -m space --focus 6
        ${modifier} - 7 : ${yabai} -m space --focus 7
        ${modifier} - 8 : ${yabai} -m space --focus 8
        ${modifier} - 9 : ${yabai} -m space --focus 9
        ${modifier} - 0 : ${yabai} -m space --focus 10

        ${modifier} + shift - y : ${yabai} -m space --mirror y-axis
        ${modifier} + shift - x : ${yabai} -m space --mirror x-axis

        # send window to next/prev space and follow focus
        ${mod4} + shift - ${left} :   ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        ${mod4} + shift - ${down} :   ${yabai} -m window --space next; ${yabai} -m space --focus next
        ${mod4} + shift - ${up} :     ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        ${mod4} + shift - ${right} :  ${yabai} -m window --space next; ${yabai} -m space --focus next
        ${mod4} + shift - left :      ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        ${mod4} + shift - down :      ${yabai} -m window --space next; ${yabai} -m space --focus next
        ${mod4} + shift - up :        ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        ${mod4} + shift - right :     ${yabai} -m window --space next; ${yabai} -m space --focus next

        # focus window in stacked, else in bsp
        ${modifier} - ${left} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
        ${modifier} - ${down} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
        ${modifier} - ${up} :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
        ${modifier} - ${right} :  if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
        ${modifier} - left :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
        ${modifier} - down :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
        ${modifier} - up :        if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
        ${modifier} - right :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
        
        # swap managed window
        ${modifier} + shift - ${left} :   ${yabai} -m window --swap west
        ${modifier} + shift - ${down} :   ${yabai} -m window --swap south
        ${modifier} + shift - ${up} :     ${yabai} -m window --swap north
        ${modifier} + shift - ${right} :  ${yabai} -m window --swap east
        ${modifier} + shift - left :      ${yabai} -m window --swap west
        ${modifier} + shift - down :      ${yabai} -m window --swap south
        ${modifier} + shift - up :        ${yabai} -m window --swap north
        ${modifier} + shift - right :     ${yabai} -m window --swap east

        # increase window size #FIXME: edit window resizing shortcuts!
        ${modifier} + shift - a : ${yabai} -m window --resize left:-20:0
        ${modifier} + shift - s : ${yabai} -m window --resize right:-20:0

        # toggle layout
        ${modifier} - s : ${yabai} -m space --layout stack
        ${modifier} - e : ${yabai} -m space --layout bsp

        # float / unfloat window and center on screen
        ${modifier} + shift - space : ${yabai} -m window --toggle float; \
                  ${yabai} -m window --grid 4:4:1:1:2:2

        # # toggle sticky(+float), topmost, picture-in-picture
        # ${modifier} - p : ${yabai} -m window --toggle sticky; \
        #           ${yabai} -m window --toggle topmost; \
        #           ${yabai} -m window --toggle pip

        # reload
        ${modifier} + shift - r : fix-wm
      '';
    };
}
