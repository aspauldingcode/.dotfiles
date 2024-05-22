{ config, pkgs, ... }:

{
  home.file.yabai = {
    executable = true;
    target = ".config/yabai/yabairc";
    text =
      let
        inherit (config.colorScheme) colors;
      in
      # bash
      ''
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
        yabai -m config mouse_modifier              alt # alt is fixed as of Yabai v7.0.0!
        yabai -m config mouse_action1               move
        yabai -m config mouse_action2               resize
        yabai -m config mouse_drop_action           swap
        yabai -m config focus_follows_mouse         autoraise # autofocus | autoraise
        yabai -m config mouse_follows_focus         on

        # window appearance
        yabai -m config window_shadow               float # floating windows only
        yabai -m config window_opacity              on
        yabai -m config window_opacity_duration     0.1
        yabai -m config window_animation_duration	  0.35 #commented out
        yabai -m config window_animation_easing     ease_in_out_circ
        yabai -m config window_opacity_duration     0.35
        yabai -m config normal_window_opacity	      0.95
        yabai -m config active_window_opacity	      1.0
        yabai -m config insert_feedback_color       0xff${colors.base0C}

        # layout
        yabai -m config layout                      bsp # bsp | float
        yabai -m config auto_balance                off
        yabai -m config split_ratio                 0.50
        yabai -m config window_placement            second_child
        yabai -m config window_origin_display       default
        yabai -m config display_arrangement_order horizontal # default | vertical
        yabai -m config window_zoom_persist         on

        # floating windows are always on top
        # when enabling this option, overlays in chrome are hidden
        # this affects popups like site search or bitwarden extension
        # yabai -m config window_topmost off

        # manage new window on the FOCUSED display on creation!
        yabai -m config window_origin_display cursor # default | focused | cursor

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
        yabai -m rule --add title="XQuartz"             manage=off
        yabai -m rule --add app='XQuartz'               manage=off
        yabai -m rule --add app='^XQuartz$'             manage=off
        yabai -m rule --add app='^X11.bin$'             manage=off
        yabai -m rule --add app='X11.bin'               manage=off
        yabai -m rule --add app='X11'                   manage=off
        yabai -m rule --add app='Archive Utility'       manage=off
        yabai -m rule --add app='Display Calibrator'    manage=off
        yabai -m rule --add app='Installer'             manage=off
        yabai -m rule --add app='Karabiner-EventViewer' manage=off
        yabai -m rule --add app='Karabiner-Elements'    manage=off
        yabai -m rule --add app='macOS InstantView'     manage=off # IMPORTANT
        yabai -m rule --add app='Dock'                  manage=off # MAKE SURE


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
              
        #  MENUBAR_OPACITY [<float_sel>]
        # cHANGES THE TRANSPARENCY OF THE MACos MENUBAR.
        # iF THE VALUE IS 0.0, THE MENUBAR WILL NO LONGER
        # RESPOND TO MOUSE-EVENTS, EFFECTIVELY HIDING THE
        # MENUBAR PERMANENTLY.
        # tHE MENUBAR WILL AUTOMATICALLY BECOME FULLY
        # OPAQUE UPON ENTERING A NATIVE-FULLSCREEN SPACE,
        # AND ADJUSTED down afterwards.

        # yabai -m config menubar_opacity 0.0 # Disables MacOS Menubar.
        toggle-menubar off

        # Borders!
        borders

        echo "yabai configuration loaded.."
      '';
  };

  home.file.skhd = {
      executable = true;
      target = ".config/skhd/skhdrc";
      text =
        let
          left = "h";
          down = "j";
          up = "k";
          right = "l";
          mod1 = "alt";
          mod4 = "cmd";
          mod5 = "ctrl";
          modifier = mod1;
          yabai = "/opt/homebrew/bin/yabai"; # Apparently required to work at all
        in # bash
        ''
          # FIXME: use kitty terminal for yazi filemanager only.

          # Launch shortcuts
          ${modifier} - return :                open -na /opt/homebrew/bin/alacritty #FIXME: Alacritty is broken atm. Using homebrew. 
          #${modifier} - return : 		    open -a kitty -n
          # ${modifier} - return :              alacritty
          ${modifier} - d :                     open -a dmenu-mac
          ${mod1} + ${mod5} - space :           open -na "Brave Browser"
          ${mod1} + shift + ${mod5} - space :   open -na "Brave Browser" --args --incognito
          ${mod1} + ${mod4} + ${mod5} - space : open -na "Brave Browser" --args --tor
          ${mod4} + ${mod5} - 0x33 :            sudo reboot # using cmd ctrl backspace
          ${mod4} + ${mod5} + shift - 0x33 :    sudo shutdown -h now # using cmd ctrl backspace
          ${mod4} + ${mod5} - delete :          sudo reboot
          ${mod4} + ${mod5} + shift - delete :  sudo shutdown -h now
          ${modifier} + shift - q :             ${yabai} -m window --close
          ${modifier} - f :                     ${yabai} -m window --toggle zoom-fullscreen 
          ${modifier} + shift - f :             toggle-instant-fullscreen

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
          ${modifier} + shift - 1 : move-to-space _1
          ${modifier} + shift - 2 : move-to-space _2
          ${modifier} + shift - 3 : move-to-space _3
          ${modifier} + shift - 4 : move-to-space _4
          ${modifier} + shift - 5 : move-to-space _5
          ${modifier} + shift - 6 : move-to-space _6
          ${modifier} + shift - 7 : move-to-space _7
          ${modifier} + shift - 8 : move-to-space _8
          ${modifier} + shift - 9 : move-to-space _9
          ${modifier} + shift - 0 : move-to-space _10
           
          # move focused space to workspace n
          ${modifier} - 1 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_1")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _1); ${yabai} -m space --focus _1
          ${modifier} - 2 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_2")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _2); ${yabai} -m space --focus _2
          ${modifier} - 3 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_3")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _3); ${yabai} -m space --focus _3
          ${modifier} - 4 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_4")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _4); ${yabai} -m space --focus _4
          ${modifier} - 5 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_5")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _5); ${yabai} -m space --focus _5
          ${modifier} - 6 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_6")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _6); ${yabai} -m space --focus _6
          ${modifier} - 7 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_7")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _7); ${yabai} -m space --focus _7
          ${modifier} - 8 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_8")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _8); ${yabai} -m space --focus _8
          ${modifier} - 9 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_9")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _9); ${yabai} -m space --focus _9
          ${modifier} - 0 : ${yabai} -m query --spaces | jq -e '.[] | select(.label == "_10")' > /dev/null || (${yabai} -m space --create && ${yabai} -m space --focus last && ${yabai} -m space --label _10); ${yabai} -m space --focus _10

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
           
          # swap managed window (or move if floating) 
          ${modifier} + shift - ${left} :   ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${modifier} + shift - ${down} :   ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${modifier} + shift - ${up} :     ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${modifier} + shift - ${right} :  ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0
          ${modifier} + shift - left :      ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${modifier} + shift - down :      ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${modifier} + shift - up :        ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${modifier} + shift - right :     ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0

          # increase window size
          ${modifier} + ctrl - ${left} :  ${yabai} -m window --resize left:-30:0
          ${modifier} + ctrl - ${down} :  ${yabai} -m window --resize bottom:0:30
          ${modifier} + ctrl - ${up} :    ${yabai} -m window --resize top:0:-30
          ${modifier} + ctrl - ${right} : ${yabai} -m window --resize right:30:0
          ${modifier} + ctrl - left :     ${yabai} -m window --resize left:-30:0
          ${modifier} + ctrl - down :     ${yabai} -m window --resize bottom:0:30
          ${modifier} + ctrl - up :       ${yabai} -m window --resize top:0:-30
          ${modifier} + ctrl - right :    ${yabai} -m window --resize right:30:0

          # decrease window size
          ${modifier} + shift + ctrl - ${left} :  ${yabai} -m window --resize left:30:0
          ${modifier} + shift + ctrl - ${down} :  ${yabai} -m window --resize bottom:0:-30
          ${modifier} + shift + ctrl - ${up} :    ${yabai} -m window --resize top:0:30
          ${modifier} + shift + ctrl - ${right} : ${yabai} -m window --resize right:-30:0
          ${modifier} + shift + ctrl - left :     ${yabai} -m window --resize left:30:0
          ${modifier} + shift + ctrl - down :     ${yabai} -m window --resize bottom:0:-30
          ${modifier} + shift + ctrl - up :       ${yabai} -m window --resize top:0:30
          ${modifier} + shift + ctrl - right :    ${yabai} -m window --resize right:-30:0

          # set insertion point in focused container
          ${modifier} - b : ${yabai} -m window --insert east
          ${modifier} - v : ${yabai} -m window --insert south

          # rotate tree
          ${modifier} - r : ${yabai} -m space --rotate 270
          ${modifier} - t : ${yabai} -m space --rotate 90

          # toggle layout
          ${modifier} - s : ${yabai} -m space --layout stack
          ${modifier} - e : ${yabai} -m space --layout bsp

          # float / unfloat window and center on screen
          ${modifier} + shift - space : ${yabai} -m window --toggle float; ${yabai} -m window --grid 60:60:5:5:50:50

          # # toggle sticky(+float), topmost, picture-in-picture
          # ${modifier} - p : ${yabai} -m window --toggle sticky; \
          #           ${yabai} -m window --toggle topmost; \
          #           ${yabai} -m window --toggle pip

          # equalize windows
          # alt + shift - u : ${yabai} -m space --balance

          # toggle sketchybar
          ${modifier} - m : toggle-sketchybar

          # toggle native macOS menubar, or dock
          #${modifier} + shift - m : toggle-menubar
          #${modifier} + shift - m : bash -e "toggle-menubar"
          #${modifier} + shift - m : osascript -e 'do shell script "open -n -a Settings"' 
          #${modifier} + shift - m : #$#{#pkgs.toggle-menubar}/bin/toggle-menubar 
          ${modifier} + shift - m : /etc/profiles/per-user/alex/bin/toggle-menubar

          ${modifier} - space : toggle-dock

          # toggle gaps
          ${modifier} - g : toggle-gaps

          # toggle-darkmode
          ${modifier} - p : toggle-darkmode

          # clear notifications 
          ${modifier} - c : dismiss-notifications

          # reload
          ${modifier} + shift - r : fix-wm

          # Blacklist applications
          .blacklist [
            "terminal"
            "qutebrowser"
            "google chrome"
            "xquartz"
          ]
      '';
    };

  home.file.jankyborders = {
    executable = true;
    target = ".config/borders/bordersrc";
    text =
      let
        inherit (config.colorScheme) colors;
      in
      # bash
      ''
        #!/bin/bash

        options=(
          style=round
          order=above
          width=2.0
          hidpi=on
          active_color=0xff"${colors.base0C}"
          inactive_color=0xff"${colors.base03}"
          blacklist="google chrome, vmware fusion, xquartz, dmenu-mac"
        )

        borders "''${options[@]}"  
      '';
  };
}