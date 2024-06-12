{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
in
{
  home.file.yabai = {
    executable = true;
    target = ".config/yabai/yabairc";
    text =
      let
          borders = "${config.home.homeDirectory}/Downloads/JankyBorders-main/bin/borders"; #FIXME: master contains apply-to=<window-id> so use this for now.
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

        # bar signal configuration
        yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus &> /dev/null"
        yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces &> /dev/null"
        yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces &> /dev/null"
        yabai -m signal --add event=window_title_changed action="sketchybar --trigger title_change &> /dev/null"

        # move/resize windows with mouse
        yabai -m config mouse_modifier              alt # alt is fixed as of Yabai v7.0.0!
        yabai -m config mouse_action1               move
        yabai -m config mouse_action2               resize
        yabai -m config mouse_drop_action           swap
        yabai -m config focus_follows_mouse         autoraise # autofocus | autoraise # use autoraise.
        yabai -m config mouse_follows_focus         on

        # window appearance
        yabai -m config window_shadow               float # floating windows only
        yabai -m config window_opacity              on
        yabai -m config window_opacity_duration     0.1
        #yabai -m config window_animation_duration	  0.35 #commented out
        #yabai -m config window_animation_easing     ease_in_out_circ
        yabai -m config window_opacity_duration     0.35
        yabai -m config normal_window_opacity	      0.95
        yabai -m config active_window_opacity	      1.0
        yabai -m config insert_feedback_color       0xff${colors.base07}

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
        yabai -m config external_bar all:50:0

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
        yabai -m config menubar_opacity 1.0 # initialize so sketchybar can create alias items.
        toggle-menubar off

        # Borders!
        ${borders}

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
          smod = "shift";
          yabai = "/opt/homebrew/bin/yabai"; # Apparently required to work at all
          i3-msg = "/opt/local/bin/i3-msg";
          alacritty = "/opt/homebrew/bin/alacritty";
          dmenu-mac = "/opt/homebrew/bin/dmenu-mac";
        in # bash
        ''
          # FIXME: use kitty terminal for yazi filemanager only.

          # Launch shortcuts
          # ${modifier} - return :                open -na ${alacritty} #FIXME: Alacritty is broken atm. Using homebrew. 
          # ${modifier} - return : 		            open -a kitty -n
          # ${modifier} - return :                ${alacritty}
          ${modifier} - return :                ${alacritty} msg create-window || open -na ${alacritty}
          ${modifier} - d :                     ${dmenu-mac}
          ${mod1} + ${mod5} - space :           open -na "Brave Browser"
          ${mod1} + ${smod} + ${mod5} - space :   open -na "Brave Browser" --args --incognito
          ${mod1} + ${mod4} + ${mod5} - space : open -na "Brave Browser" --args --tor
          ${mod4} + ${mod5} - 0x33 :            sudo reboot # using cmd ctrl backspace
          ${mod4} + ${mod5} + ${smod} - 0x33 :    sudo shutdown -h now # using cmd ctrl backspace
          ${mod4} + ${mod5} - delete :          sudo reboot
          ${mod4} + ${mod5} + ${smod} - delete :  sudo shutdown -h now
          ${modifier} + ${smod} - q :             ${yabai} -m window --close
          ${modifier} - f :                     ${yabai} -m window --toggle zoom-fullscreen 
          ${modifier} + ${smod} - f :             toggle-instant-fullscreen

          # Move focus to next/prev workspace
          ${mod1} + ${mod4} - ${left} :   ${yabai} -m space --focus prev
          ${mod1} + ${mod4} - ${down} :   ${yabai} -m space --focus prev
          ${mod1} + ${mod4} - ${up} :     ${yabai} -m space --focus next
          ${mod1} + ${mod4} - ${right} :  ${yabai} -m space --focus next
          ${mod1} + ${mod4} - left :      ${yabai} -m space --focus prev
          ${mod1} + ${mod4} - down :      ${yabai} -m space --focus prev
          ${mod1} + ${mod4} - up :        ${yabai} -m space --focus next
          ${mod1} + ${mod4} - right :     ${yabai} -m space --focus next

          # Move focused window to workspace N and follow focus
          ${modifier} + ${smod} - 1 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _1
          ${modifier} + ${smod} - 2 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _2
          ${modifier} + ${smod} - 3 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _3
          ${modifier} + ${smod} - 4 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _4
          ${modifier} + ${smod} - 5 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _5
          ${modifier} + ${smod} - 6 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _6
          ${modifier} + ${smod} - 7 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _7
          ${modifier} + ${smod} - 8 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _8
          ${modifier} + ${smod} - 9 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _9
          ${modifier} + ${smod} - 0 : ${yabai} -m space --create && ${yabai} -m window --space last && ${yabai} -m space --focus last && ${yabai} -m space --label _10
          
          # move focus to workspace n
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

          ${modifier} + ${smod} - y : ${yabai} -m space --mirror y-axis
          ${modifier} + ${smod} - x : ${yabai} -m space --mirror x-axis

          # send window to next/prev space and follow focus
          ${mod4} + ${smod} - ${left} :   ${yabai} -m window --space prev; ${yabai} -m space --focus prev
          ${mod4} + ${smod} - ${down} :   ${yabai} -m window --space next; ${yabai} -m space --focus next
          ${mod4} + ${smod} - ${up} :     ${yabai} -m window --space prev; ${yabai} -m space --focus prev
          ${mod4} + ${smod} - ${right} :  ${yabai} -m window --space next; ${yabai} -m space --focus next
          ${mod4} + ${smod} - left :      ${yabai} -m window --space prev; ${yabai} -m space --focus prev
          ${mod4} + ${smod} - down :      ${yabai} -m window --space next; ${yabai} -m space --focus next
          ${mod4} + ${smod} - up :        ${yabai} -m window --space prev; ${yabai} -m space --focus prev
          ${mod4} + ${smod} - right :     ${yabai} -m window --space next; ${yabai} -m space --focus next

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
          ${modifier} + ${smod} - ${left} :   ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${modifier} + ${smod} - ${down} :   ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${modifier} + ${smod} - ${up} :     ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${modifier} + ${smod} - ${right} :  ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0
          ${modifier} + ${smod} - left :      ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${modifier} + ${smod} - down :      ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${modifier} + ${smod} - up :        ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${modifier} + ${smod} - right :     ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0

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
          ${modifier} + ${smod} + ctrl - ${left} :  ${yabai} -m window --resize left:30:0
          ${modifier} + ${smod} + ctrl - ${down} :  ${yabai} -m window --resize bottom:0:-30
          ${modifier} + ${smod} + ctrl - ${up} :    ${yabai} -m window --resize top:0:30
          ${modifier} + ${smod} + ctrl - ${right} : ${yabai} -m window --resize right:-30:0
          ${modifier} + ${smod} + ctrl - left :     ${yabai} -m window --resize left:30:0
          ${modifier} + ${smod} + ctrl - down :     ${yabai} -m window --resize bottom:0:-30
          ${modifier} + ${smod} + ctrl - up :       ${yabai} -m window --resize top:0:30
          ${modifier} + ${smod} + ctrl - right :    ${yabai} -m window --resize right:-30:0

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
          #${modifier} + ${smod} - space : ${yabai} -m window --toggle float; ${yabai} -m window --grid 60:60:5:5:50:50
          ${modifier} + ${smod} - space : toggle-float

          # # toggle sticky(+float), topmost, picture-in-picture
          # ${modifier} - p : ${yabai} -m window --toggle sticky; \
          #           ${yabai} -m window --toggle topmost; \
          #           ${yabai} -m window --toggle pip

          # equalize windows
          # ${modifier} + ${smod} - u : ${yabai} -m space --balance

          # toggle sketchybar
          ${modifier} - m : toggle-sketchybar

          # toggle native macOS menubar, or dock
          #${modifier} + ${smod} - m : current=$(osascript -e 'tell application "System Events" to tell dock preferences to get autohide menu bar'); new_state=$(if [[ "$1" == "on" ]]; then echo false; elif [[ "$1" == "off" ]]; then echo true; else [[ "$current" == "true" ]] && echo false || echo true; fi); osascript -e "tell application \"System Events\" to tell dock preferences to set autohide menu bar to $new_state" && ${yabai} -m config menubar_opacity $(if [[ "$new_state" == "true" ]]; then echo 0.0; else echo 1.0; fi) && echo "Menu bar turned $(if [[ "$new_state" == "true" ]]; then echo OFF; else echo ON; fi)"
          ${modifier} + ${smod} - m : toggle-menubar

          ${modifier} - space : toggle-dock

          # toggle gaps
          ${modifier} - g : toggle-gaps

          # toggle-darkmode
          ${modifier} - p : toggle-darkmode

          # clear notifications 
          ${modifier} - c : dismiss-notifications

          # reload
          ${modifier} + ${smod} - r : fix-wm

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
      # bash
      #FIXME: remember: active_color='gradient(top_left=0xFF0000FF,bottom_right=0xFF00FF00)'
      ''
        #!/bin/bash

        options=(
          style=round
          order=above
          width=2.0
          background_color=0x11${colors.base00}
          blur_radius=15.0
          hidpi=on
          active_color=0xff${colors.base07}
          inactive_color=0xff${colors.base05}
          blacklist="google chrome, vmware fusion, xQuartz, dmenu-mac, X11.bin"
        )

        borders "''${options[@]}"
      '';
  };
}
