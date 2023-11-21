{ config, pkgs, lib, ... }: {
  home.file.yabai = {
    executable = true;
    target = ".config/yabai/yabairc";
    text = ''
      #!/usr/bin/env sh

      # load scripting addition
      sudo yabai --load-sa
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

      # bar configuration
      yabai -m config external_bar all:0:45
      yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
      yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
      yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"

      # move/resize windows with mouse
      yabai -m config mouse_modifier              alt
	  yabai -m config mouse_action1               move
      yabai -m config mouse_action2               resize
      yabai -m config focus_follows_mouse         autofocus
      yabai -m config mouse_follows_focus         off #FIXME: configure apps so I can turn this on.

      # borders #REMOVED, upgrading to Sonoma with JANKYBORDERS!
      # yabai -m config window_border               on
      # yabai -m config window_border_placement     inset
      # yabai -m config window_border_width         2
      # yabai -m config window_border_radius        11
      # yabai -m config window_border_blur          off
      # yabai -m config active_window_border_color  0xffA34A28
      # yabai -m config normal_window_border_color  0xff808080
      # yabai -m config insert_feedback_color       0xff808080

      #UPGRADED to Sonoma. JankyBorders installed
      borders active_color=0xffA34A28 inactive_color=0xff808080 width=5.0 2>/dev/null 1>&2 &

      e window appearance
      yabai -m config window_shadow               off
      yabai -m config window_opacity              on
      yabai -m config window_opacity_duration     0.1
      
      # layout
      yabai -m config layout                      bsp
      yabai -m config auto_balance                off
      yabai -m config split_ratio                 0.50
      yabai -m config window_placement            second_child

      # floating windows are always on top
      # when enabling this option, overlays in chrome are hidden
      # this affects popups like site search or bitwarden extension
      #yabai -m config window_topmost off

      # gaps
      yabai -m config top_padding    60
      yabai -m config bottom_padding 15
      yabai -m config left_padding   15
      yabai -m config right_padding  15
      yabai -m config window_gap     15

      # rules
      yabai -m rule --add app="^System Settings$"    manage=off
      yabai -m rule --add app="^System Information$" manage=off
      yabai -m rule --add app="^System Preferences$" manage=off
      yabai -m rule --add title="Preferences$"       manage=off
      yabai -m rule --add title="Settings$"          manage=off

      # workspace management
      yabai -m space 1  --label term
      yabai -m space 2  --label code
      yabai -m space 3  --label www
      yabai -m space 4  --label chat
      yabai -m space 5  --label todo
      yabai -m space 6  --label music
      yabai -m space 7  --label voice
      yabai -m space 8  --label eight
      yabai -m space 9  --label nine
      yabai -m space 10 --label ten

      # assign apps to spaces
      yabai -m rule --add app="Alacritty" space=code
      yabai -m rule --add app="Visual Studio Code" space=code

      yabai -m rule --add app="Vivaldi" space=www
      yabai -m rule --add app="Arc" space=www

      yabai -m rule --add app="Slack" space=chat
      yabai -m rule --add app="Signal" space=chat

      yabai -m rule --add app="Todoist" space=todo

      yabai -m rule --add app="Spotify" space=music

      yabai -m rule --add app="Mumble" space=voice

      yabai -m rule --add app="Google Chrome" space=eight

      yabai -m rule --add app="Microsoft Teams" space=nine

      yabai -m rule --add app='System Settings' manage=off
	  yabai -m rule --add app='System Information' manage=off
	  yabai -m rule --add app='zoom.us' manage=off
      yabai -m rule --add app='Finder' manage=off
      yabai -m rule --add app='Archive Utility' manage=off
      yabai -m rule --add app='Display Calibrator' manage=off
      yabai -m rule --add app='Installer' manage=off
      echo "yabai configuration loaded.."
    '';
  };

  home.file.skhd = {
    executable = true;
    target = ".config/skhd/skhdrc";
    text = let yabai = "/opt/homebrew/bin/yabai"; in
      ''
        # alt + a / u / o / s are blocked due to umlaute
        
        # Launch shortcuts
        alt - return : open -na alacritty
        alt - d : open -a dmenu-mac
        alt + cmd - space : open -na "Brave Browser"
        ctrl + cmd - 0x33 : sudo reboot
        ctrl + shift + cmd - 0x33 : sudo shutdown -h now
        ctrl + cmd - delete : sudo reboot
        ctrl + shift + cmd - delete : sudo shutdown -h now
        alt + shift - space : yabai -m window --toggle float

        alt + shift - q : yabai -m window --close
		alt - f : yabai -m window --toggle zoom-fullscreen
        #alt + shift - f : yabai -m window --toggle native-fullscreen #DON'T that thing SUCKS

        # workspaces
        # ctrl + alt - j : ${yabai} -m space --focus prev
        ctrl + alt - k : ${yabai} -m space --focus next
        cmd + alt - j : ${yabai} -m space --focus prev
        cmd + alt - k : ${yabai} -m space --focus next

        # move focused window to next/prev workspace
        alt + shift - 1 : ${yabai} -m window --space 1
        alt + shift - 2 : ${yabai} -m window --space 2
        alt + shift - 3 : ${yabai} -m window --space 3
        alt + shift - 4 : ${yabai} -m window --space 4
        alt + shift - 5 : ${yabai} -m window --space 5
        alt + shift - 6 : ${yabai} -m window --space 6
        alt + shift - 7 : ${yabai} -m window --space 7
        alt + shift - 8 : ${yabai} -m window --space 8
        alt + shift - 9 : ${yabai} -m window --space 9
        alt + shift - 0 : ${yabai} -m window --space 10

        alt + shift - y : ${yabai} -m space --mirror y-axis
        alt + shift - x : ${yabai} -m space --mirror x-axis

        # send window to space and follow focus
        ctrl + alt - l : ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        ctrl + alt - h : ${yabai} -m window --space next; ${yabai} -m space --focus next
        cmd + alt - l : ${yabai} -m window --space prev; ${yabai} -m space --focus prev
        cmd + alt - h : ${yabai} -m window --space next; ${yabai} -m space --focus next

        # focus window in stacked
        alt - j : if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus south; fi
        alt - k : if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus north; fi
        
        # focus window
        alt - h :     ${yabai} -m window --focus west
        alt - j :     ${yabai} -m window --focus south
        alt - k :     ${yabai} -m window --focus north
        alt - l :     ${yabai} -m window --focus east
        alt - left :  ${yabai} -m window --focus west
        alt - down :  ${yabai} -m window --focus south
        alt - up :    ${yabai} -m window --focus north
        alt - right : ${yabai} -m window --focus east

        # swap managed window
        shift + alt - h :     ${yabai} -m window --swap west
        shift + alt - j :     ${yabai} -m window --swap south
        shift + alt - k :     ${yabai} -m window --swap north
        shift + alt - l :     ${yabai} -m window --swap east
        shift + alt - left :  ${yabai} -m window --swap west
        shift + alt - down :  ${yabai} -m window --swap south
        shift + alt - up :    ${yabai} -m window --swap north
        shift + alt - right : ${yabai} -m window --swap east

        # increase window size
        shift + alt - a : ${yabai} -m window --resize left:-20:0
        shift + alt - s : ${yabai} -m window --resize right:-20:0

        # toggle layout
        alt - t : ${yabai} -m space --layout bsp
        alt - d : ${yabai} -m space --layout stack

        # float / unfloat window and center on screen
        alt - n : ${yabai} -m window --toggle float; \
                  ${yabai} -m window --grid 4:4:1:1:2:2

        # toggle sticky(+float), topmost, picture-in-picture
        alt - p : ${yabai} -m window --toggle sticky; \
                  ${yabai} -m window --toggle topmost; \
                  ${yabai} -m window --toggle pip

        # reload
        shift + alt - r : skhd --restart-service; yabai --restart-service; brew services restart sketchybar
      '';
  };
}
