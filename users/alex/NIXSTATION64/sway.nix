{ config, pkgs, ...}:

{
  imports = [
    ./waybar.nix
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    config = rec {
      bars = [
        {command = "${pkgs.waybar}/bin/waybar";}#FIXME: WHY ARE THERE TWO WAYBARS at launch?
      ];
      modifier = "Mod4";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      output = {
        DP-4 = { 
          res = "1920x1080";
          pos = "0,0"; 
          transform = "270";
          #bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/ghibliwp.jpg fill";
        };
        DP-3 = {
          res = "1920x1080";
          pos = "1080,450";
          #bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/ghibliwp.jpg fill";
        };
        DP-2 = {
          res = "1920x1080"; 
          pos = "3000,450";
          #bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/ghibliwp.jpg fill";
        };
        "*" = { # change background for all outputs
          bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/ghibliwp.jpg fill";
        };
      };
      # Use alacritty as default terminal
      terminal = "alacritty"; 
      startup = [
        # Launch alacritty on start
        {command = "alacritty";} #FIXME: DOES ALACRITTY ACTUALLY LAUNCH?!?!?
      ];
      menu = "bemenu-run";

      workspaceLayout = "default";
      keybindings = {
        "${modifier}+f" = "exec maximize"; #custom script for zoom-fullscreen NOTWORKING?
        "${modifier}+Shift+f" = "fullscreen toggle";
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Alt+Space" = "exec brave";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+q" = "exec wtype -M ctrl -P w -m ctrl -p w";
        "${modifier}+a" = "exec show-all-windows";
        "${modifier}+d" = "exec ${menu}";
        "${modifier}+m" = "exec docker start -ai 8b83fcdf83af"; # MacOS VM
        "Control+Alt+Delete" = "exec sudo reboot";
        "Control+Shift+Alt+Delete" = "exec sudo shutdown now";
        # implement window switcher based on wofi
        #"${modifier}+Tab" = "exec ${wofiWindowJump}";
        # power menu
        #"${modifier}+Insert" = "exec ${wofiPower}";
        # clipboard history
        #"${modifier}+v" = "exec ${pkgs.clipman}/bin/clipman pick --tool wofi";
        # Output pressed keycode using xev:
        # nix-shell -p xorg.xev --run "xev | grep -A2 --line-buffered '^KeyRelease' | sed -n '/keycode /s/^.*keycode \([0-9]*\).* (.*, \(.*\)).*$/\1 \2/p'"
        # fn+F1    c:121   XF86AudioMute
        #"XF86AudioMute" = ''exec ${pamixer} --toggle-mute && ( ${pamixer} --get-mute && ${mywob} 0 ) || ${mywob} $(${pamixer} --get-volume)'';
        # fn+F2    c:122   XF86AudioLowerVolume
        #"XF86AudioLowerVolume" = ''exec ${pamixer} --allow-boost --unmute --decrease 2 && ${mywob} $(${pamixer} --get-volume)'';
        # fn+F3    c:123   XF86AudioRaiseVolume
        #"XF86AudioRaiseVolume" = ''exec ${pamixer} --allow-boost --unmute --increase 2 && ${mywob} $(${pamixer} --get-volume)'';
        # fn+F4    c:198   XF86AudioMicMute
        #"XF86AudioMicMute" = ''exec ${pamixer} --default-source --toggle-mute && ( ${pamixer} --default-source --get-mute && ${mywob} 0 ) || ${mywob} $(${pamixer} --default-source --get-volume)'';
        # fn+F5    c:232   XF86MonBrightnessDown
        # "--locked XF86MonBrightnessDown" = ''exec ${mywob} $(${brightnessctl} set 5%- | ${sed} -En 's/.*\(([0-9]+)%\).*/#\1/p')'';
        ## fn+F6    c:233   XF86MonBrightnessUp
        # "--locked XF86MonBrightnessUp" = ''exec ${mywob} $(${brightnessctl} set +5% | ${sed} -En 's/.*\(([0-9]+)%\).*/\1/p')'';
        # fn+F7    c:235   XF86Display
        ## fn+F8    c:246   XF86WLAN
        ## fn+F9    c:179   XF86Tools
        ## fn+F10   c:225   XF86Search
        ## fn+F11   c:128   XF86LaunchA
        ## fn+F12   c:152   XF86Explorer
        #"XF86Calculator" = "exec ${pkgs.gnome.gnome-calculator}/bin/gnome-calculator";
        # "XF86???Lock" = "";
        #"XF86HomePage" = "exec ${pkgs.firefox-wayland}/bin/firefox";
        # "XF86???FOLDER" = "";

        # Screenshot
        "Alt+Shift+3" = "exec screenshot"; # All visible outputs
        "Alt+Shift+4" = ''exec grimshot --notify save window ~/Desktop/"Screenshot $(date '+%Y-%m-%d at %I.%M.%S %p').png"'';


        # Screen recording
        #"${modifier}+Print" = "exec wayrecorder --notify screen";
        #"${modifier}+Shift+Print" = "exec wayrecorder --notify --input area";
        #"${modifier}+Alt+Print" = "exec wayrecorder --notify --input active";
        #"${modifier}+Shift+Alt+Print" = "exec wayrecorder --notify --input window";
        #"${modifier}+Ctrl+Print" = "exec wayrecorder --notify --clipboard --input screen";
        #"${modifier}+Ctrl+Shift+Print" = "exec wayrecorder --notify --clipboard --input area";
        #"${modifier}+Ctrl+Alt+Print" = "exec wayrecorder --notify --clipboard --input active";
        #"${modifier}+Ctrl+Shift+Alt+Print" = "exec wayrecorder --notify --clipboard --input window";

        # "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl -s previous";
        # "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl -s next";
        # "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl -s play-pause";
        # "XF86AudioStop" = "exec ${pkgs.playerctl}/bin/playerctl -s stop";
        # "Control+XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl -s position 30-";
        # "Control+XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl -s position 30+";
        # "Control+XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl -s stop";

        #"${modifier}+l" = "exec ${locksway}";

        #"${modifier}+Shift+minus" = "exec ${outputScale} -.1";
        #"${modifier}+Shift+equal" = "exec ${outputScale} +.1";
        "${modifier}+Shift+Ctrl+minus" = "move scratchpad"; # Change to control alt down
        "${modifier}+Shift+Ctrl+equal" = "scratchpad show"; # change to control alt up

        "${modifier}+r" = "mode resize"; #??? orrresize mode

        "${modifier}+Shift+Space" = "floating toggle";
        "${modifier}+Space" = "focus mode_toggle";
        "${modifier}+u" = "focus parent";

        "${modifier}+w" = "layout toggle split";
        "${modifier}+s" = "layout tabbed"; #macos is stacked layout
        "${modifier}+e" = "layout default";

        #"${modifier}+o" = "inhibit_idle open; border normal; mark --add inhibiting_idle";
        #"${modifier}+Shift+o" = "inhibit_idle none; border pixel; unmark inhibiting_idle";

        #"${modifier}+j" = "exec ${pkgs.mako}/bin/makoctl invoke"; # Invoke default action on top notification.
        #"${modifier}+Shift+t" = "exec ${pkgs.flashfocus}/bin/flash_window";

        # Change focused window
        "${modifier}+${left}" =   "focus left";
        "${modifier}+${down}" =   "focus down";
        "${modifier}+${up}" =     "focus up";
        "${modifier}+${right}" =  "focus right";
        "${modifier}+Left" =      "focus left";
        "${modifier}+Down" =      "focus down";
        "${modifier}+Up" =        "focus up";
        "${modifier}+Right" =     "focus right";

        #FIXME: make this swap window in place! Currently it rotates.
        #"${modifier}+Shift+${left}" =   "mark --add \"_swap\", focus left,  swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+${down}" =   "mark --add \"_swap\", focus down,  swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+${up}" =     "mark --add \"_swap\", focus up,    swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+${right}" =  "mark --add \"_swap\", focus right, swap container with mark \"_swap\", unmark \"_swap\"";        "${modifier}+Shift+Left" =      "swap left";
        #"${modifier}+Shift+Left" =      "mark --add \"_swap\", focus left,  swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+Down" =      "mark --add \"_swap\", focus down,  swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+Up" =        "mark --add \"_swap\", focus up,    swap container with mark \"_swap\", unmark \"_swap\"";
        #"${modifier}+Shift+Right" =     "mark --add \"_swap\", focus right, swap container with mark \"_swap\", unmark \"_swap\"";

        # Navigate to next/prev workspace
        "${modifier}+Ctrl+${left}" =    "workspace prev";
        "${modifier}+Ctrl+${down}" =    "workspace next";
        "${modifier}+Ctrl+${up}" =      "workspace prev";
        "${modifier}+Ctrl+${right}" =   "workspace next";
        "${modifier}+Ctrl+Left" =       "workspace prev";
        "${modifier}+Ctrl+Down" =       "workspace next";
        "${modifier}+Ctrl+Up" =         "workspace prev";
        "${modifier}+Ctrl+Right" =      "workspace next";

        # Move window to next/prev workspace and follow focus
        "Ctrl+Shift+${left}" =   "move container to workspace prev, workspace prev";
        "Ctrl+Shift+${down}" =   "move container to workspace next, workspace next";
        "Ctrl+Shift+${up}" =     "move container to workspace prev, workspace prev";
        "Ctrl+Shift+${right}" =  "move container to workspace next, workspace next";
        "Ctrl+Shift+Left" =      "move container to workspace prev, workspace prev";
        "Ctrl+Shift+Down" =      "move container to workspace next, workspace next";
        "Ctrl+Shift+Up" =        "move container to workspace prev, workspace prev";
        "Ctrl+Shift+Right" =     "move container to workspace next, workspace next";

        # Move focus to workspace n
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        # Move window to workspace n and follow focus
        "${modifier}+Shift+1" = "move container to workspace number 1, workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2, workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3, workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4, workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5, workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6, workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7, workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8, workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9, workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10, workspace number 10";

        "${modifier}+Shift+R" = "reload";
      };
    };

    extraConfig = let inherit (config.colorscheme) colors; in ''
    set $mod Mod4
      # Idle configuration        
      exec swayidle -w \
      timeout 7320 'swaylock -f -c 000000' \
      timeout 8000 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
      before-sleep 'swaylock -f -c 000000'

      # You can get the names of your inputs by running: swaymsg -t get_inputs
      # Read `man 5 sway-input` for more information about this section.
      # Launch the network manager widget!
      exec nm-applet

      #FIXME: update this to be above! moves windows.
      # Swap positions of the current window with the one on $direction
      bindsym $mod+Shift+Left  mark --add "_swap", focus left,  swap container with mark "_swap", focus left,  unmark "_swap"
      bindsym $mod+Shift+Down  mark --add "_swap", focus down,  swap container with mark "_swap", focus down,  unmark "_swap"
      bindsym $mod+Shift+Up    mark --add "_swap", focus up,    swap container with mark "_swap", focus up,    unmark "_swap"
      bindsym $mod+Shift+Right mark --add "_swap", focus right, swap container with mark "_swap", focus right, unmark "_swap"

      # SET workspace to specific output
      workspace 1 output DP-4
      workspace 2 output DP-3
      workspace 3 output DP-2

      # Launch the bluetooth applet
      exec blueman-applet

      # Delayed launch of the bluetooth applet
      exec "sleep 5 && blueman-applet"

      # autotile!
      exec autotiling

      #exec "mako --config ~/.makoe"

      # STYLIZE!
      gaps inner 13
      gaps top -2
      corner_radius 10

      #FIX waybar tooltips!
      for_window [app_id="waybar" floating] {
        move position cursor
        move down 120px # adjust if some menus still don't fit
      }

      # Enable csd borders # options are: none | normal | csd | pixel [<n>]
      bindsym $mod+Shift+B exec swaymsg border toggle

      # Window background blur
      blur on #FIXME: TURN ON! Floating window loses its borders...
      #blur_xray on
      blur_passes 2
      blur_radius 5

      shadows on
      #shadows_on_csd disable
      shadow_blur_radius 30
      shadow_color #000000ff

      # inactive window fade amount. 0.0 = no dimming, 1.0 = fully dimmed
      #default_dim_inactive .3
      #dim_inactive_colors.unfocused "#000000"
      #dim_inactive_colors.urgent "#900000"

      # HIDE CURSOR AUTOMATICALLY
      seat * hide_cursor 8000

      # HIDE TITLEBAR!
      # SET BORDER TO 2 PIXELS!
      default_border pixel 2
      default_floating_border pixel 2
      client.unfocused "#808080" "#808080" "#808080" "#808080" "#808080"
      client.focused ${colors.base0C} ${colors.base0C} ${colors.base0C} ${colors.base0C}

      exec {
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
        gsettings set org.gnome.desktop.interface icon-theme 'elementary'
        gsettings set org.gnome.desktop.interface cursor-theme 'elementary'
        gsettings set org.gnome.desktop.interface font-name 'Roboto Slab 10'
      }

      # Fix zoom
      for_window [app_id="zoom"] floating enable
      for_window [app_id="zoom" title="Choose ONE of the audio conference options"] floating enable
      for_window [app_id="zoom" title="zoom"] floating enable
      for_window [app_id="zoom" title="Zoom Meeting"] floating disable
      for_window [app_id="zoom" title="Zoom - Free Account"] floating disable
      '';
    };
  }
