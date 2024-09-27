{ config, pkgs, ... }:

let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath = if systemType == "aarch64-darwin" then "/opt/homebrew/bin" else if systemType == "x86_64-darwin" then "/usr/local/bin" else throw "Homebrew Unsupported architecture: ${systemType}";
  yabai = "${homebrewPath}/yabai";
  sketchybar = "${homebrewPath}/sketchybar";
  # borders = "${homebrewPath}/borders";
  borders = "~/JankyBorders/bin/borders";
  i3-msg = "${homebrewPath}/i3-msg";
  alacritty = "${homebrewPath}/alacritty";
  firefox = "${homebrewPath}/firefox";
  # app_menu = "${homebrewPath}/dmenu-mac";
  app_menu = "/Applications/unmenu.app/Contents/MacOS/unmenu";
  jq = "${pkgs.jq}/bin/jq";
  inherit (config.colorScheme) colors;

  desktoppr = "/usr/local/bin/desktoppr";
  wallpaper = ./../../extraConfig/wallpapers/gruvbox-nix.png;
in
{
  home.file.yabai = {
    executable = true;
    target = ".config/yabai/yabairc";
    text =
      # bash
      ''
        #!/usr/bin/env sh

        # set wallpaper first
        ${desktoppr} ${wallpaper}

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
        # focus window after active space changes
        yabai -m signal --add event=space_changed action="yabai -m window --focus \$(yabai -m query --windows --space | ${jq} .[0].id)"
        # focus window after active display changes
        yabai -m signal --add event=display_changed action="yabai -m window --focus \$(yabai -m query --windows --space | ${jq} .[0].id)"

        # move/resize windows with mouse
        yabai -m config mouse_modifier              alt # alt is fixed as of Yabai v7.0.0!
        yabai -m config mouse_action1               move
        yabai -m config mouse_action2               resize
        yabai -m config mouse_drop_action           swap
        yabai -m config focus_follows_mouse         autoraise # autofocus | autoraise # use autoraise.
        yabai -m config mouse_follows_focus         on

        # window appearance
        yabai -m config window_shadow               off # float # floating windows only
        yabai -m config window_opacity              on
        yabai -m config window_opacity_duration     0.1
        #yabai -m config window_animation_duration	  0.35 #commented out
        #yabai -m config window_animation_easing     ease_in_out_circ
        # yabai -m config window_opacity_duration     0.35
        # yabai -m config normal_window_opacity	      0.95
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
        yabai -m rule --add title=".*Preferences$"      manage=off
        yabai -m rule --add title=".*Settings$"         manage=off
        yabai -m rule --add app='^zoom\.us$'            manage=off
        yabai -m rule --add app='^Finder$'              manage=off
        yabai -m rule --add title="^XQuartz$"           manage=off
        yabai -m rule --add app='^XQuartz$'             manage=off
        yabai -m rule --add app='^X11\.bin$'            manage=off
        yabai -m rule --add app='^X11$'                 manage=off
        yabai -m rule --add app='^Archive Utility$'     manage=off
        yabai -m rule --add app='^Display Calibrator$'  manage=off
        yabai -m rule --add app='^Installer$'           manage=off
        yabai -m rule --add app='^Karabiner-EventViewer$' manage=off
        yabai -m rule --add app='^Karabiner-Elements$'  manage=off
        yabai -m rule --add app='MacForge'            manage=off
        yabai -m rule --add app='^macOS InstantView$'   manage=off # IMPORTANT
        yabai -m rule --add app='^Dock$'                manage=off # MAKE SURE


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

        mkdir -p ~/.config/yabai/cache/
        touch ~/.config/yabai/cache/lockfile
        YABAI_CACHE = ~/.config/yabai/cache/

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

        # load wallpaper!
        

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
        in # bash
        ''
          # Launch shortcuts
          ${modifier} - return :                ${alacritty} msg create-window || open -na ${alacritty}
          ${mod1} + ${mod5} - space :             open -na ${firefox}
          ${mod1} + ${smod} + ${mod5} - space :   open -na ${firefox} --args -private-window
          ${mod4} + ${mod5} - 0x33 :            sudo reboot # using cmd ctrl backspace
          ${mod4} + ${mod5} + ${smod} - 0x33 :    sudo shutdown -h now # using cmd ctrl backspace
          ${mod4} + ${mod5} - delete :          sudo reboot
          ${mod4} + ${mod5} + ${smod} - delete :  sudo shutdown -h now
          ${modifier} + ${smod} - q :           ${yabai} -m window --close
          ${modifier} - f :                     ${yabai} -m window --toggle zoom-fullscreen 
          ${modifier} + ${smod} - f :             toggle-instant-fullscreen

          # # Move focused window to workspace N and follow focus
          ${modifier} + ${smod} - 1 : ${yabai} -m window --space 1; ${yabai} -m space --focus 1; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 2 : ${yabai} -m window --space 2; ${yabai} -m space --focus 2; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 3 : ${yabai} -m window --space 3; ${yabai} -m space --focus 3; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 4 : ${yabai} -m window --space 4; ${yabai} -m space --focus 4; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 5 : ${yabai} -m window --space 5; ${yabai} -m space --focus 5; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 6 : ${yabai} -m window --space 6; ${yabai} -m space --focus 6; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 7 : ${yabai} -m window --space 7; ${yabai} -m space --focus 7; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 8 : ${yabai} -m window --space 8; ${yabai} -m space --focus 8; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 9 : ${yabai} -m window --space 9; ${yabai} -m space --focus 9; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - 0 : ${yabai} -m window --space 10; ${yabai} -m space --focus 10; ${desktoppr} ${wallpaper}
          
          # move focus to workspace n
          ${modifier} - 1 : ${yabai} -m space --focus 1; ${desktoppr} ${wallpaper}
          ${modifier} - 2 : ${yabai} -m space --focus 2; ${desktoppr} ${wallpaper}
          ${modifier} - 3 : ${yabai} -m space --focus 3; ${desktoppr} ${wallpaper}    
          ${modifier} - 4 : ${yabai} -m space --focus 4; ${desktoppr} ${wallpaper}
          ${modifier} - 5 : ${yabai} -m space --focus 5; ${desktoppr} ${wallpaper}
          ${modifier} - 6 : ${yabai} -m space --focus 6; ${desktoppr} ${wallpaper}  
          ${modifier} - 7 : ${yabai} -m space --focus 7; ${desktoppr} ${wallpaper}
          ${modifier} - 8 : ${yabai} -m space --focus 8; ${desktoppr} ${wallpaper}
          ${modifier} - 9 : ${yabai} -m space --focus 9; ${desktoppr} ${wallpaper}
          ${modifier} - 0 : ${yabai} -m space --focus 10; ${desktoppr} ${wallpaper}
          
          ${modifier} + ${smod} - y : ${yabai} -m space --mirror y-axis
          ${modifier} + ${smod} - x : ${yabai} -m space --mirror x-axis

          # send window to next/prev space and follow focus (use alt instead of cmd with arrows to maintian built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
          ${mod4} + ${smod} - ${left} :   ${yabai} -m window --space prev; ${yabai} -m space --focus prev; ${desktoppr} ${wallpaper}
          ${mod4} + ${smod} - ${down} :   ${yabai} -m window --space next; ${yabai} -m space --focus next; ${desktoppr} ${wallpaper}
          ${mod4} + ${smod} - ${up} :     ${yabai} -m window --space prev; ${yabai} -m space --focus prev; ${desktoppr} ${wallpaper}
          ${mod4} + ${smod} - ${right} :  ${yabai} -m window --space next; ${yabai} -m space --focus next; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - left :      ${yabai} -m window --space prev; ${yabai} -m space --focus prev; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - down :      ${yabai} -m window --space next; ${yabai} -m space --focus next; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - up :        ${yabai} -m window --space prev; ${yabai} -m space --focus prev; ${desktoppr} ${wallpaper}
          ${modifier} + ${smod} - right :     ${yabai} -m window --space next; ${yabai} -m space --focus next; ${desktoppr} ${wallpaper}

          # focus window in stacked, else in bsp (use cmd instead of alt with arrows to maintian built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
          ${modifier} - ${left} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
          ${modifier} - ${down} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
          ${modifier} - ${up} :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
          ${modifier} - ${right} :  if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
          ${mod4} - left :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
          ${mod4} - down :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
          ${mod4} - up :        if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
          ${mod4} - right :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
           
          # swap managed window (or move if floating) (use cmd instead of alt with arrows to maintain built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
          ${modifier} + ${smod} - ${left} :   ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${modifier} + ${smod} - ${down} :   ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${modifier} + ${smod} - ${up} :     ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${modifier} + ${smod} - ${right} :  ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0
          ${mod4} + ${smod} - left :      ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
          ${mod4} + ${smod} - down :      ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
          ${mod4} + ${smod} - up :        ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
          ${mod4} + ${smod} - right :     ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0

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

          # toggle-darkmode FIXME: NOT WORKING!
          ${modifier} - p : toggle-darkmode && toggle-theme && ${sketchybar} --reload 

          # send to scratchpad. (alt + shift + -)
          ${modifier} + ${smod} - 0x1B : highest_label=$(${yabai} -m query --windows | ${jq} '[.[] | select(.scratchpad != 0 and .scratchpad_label != null) | .scratchpad_label | select(test("^_\\d+$"))] | map(sub("^_"; "")) | map(tonumber) | max + 1') && new_label="_$highest_label" && ${yabai} -m window --scratchpad $new_label && ${yabai} -m window --toggle $new_label
          
          # recover latest from scratchpad. (alt + shift + =)
          ${modifier} + ${smod} - 0x18 : \
            highest_label=$(${yabai} -m query --windows | ${jq} '[.[] | select(.scratchpad_label != null) | .scratchpad_label] | sort | last') && \
            ${yabai} -m window --toggle $highest_label && \
            ${yabai} -m window --scratchpad ""
          
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
        background_color=0xff${colors.base00}
        hidpi=on
        active_color=0xff${colors.base07}
        inactive_color=0xff${colors.base05}
        blacklist="google chrome,vmware fusion,xQuartz,dmenu-mac,unmenu,X11.bin,MacForge,python3.11"
      )

      ${borders} "''${options[@]}"
    '';
  };
}
