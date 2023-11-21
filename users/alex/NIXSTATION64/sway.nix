{ lib, config, pkgs, ...}:

{
  imports = [
    #./hyprland-vnc.nix
    #./gammastep.nix
    #./kitty.nix
    #./mako.nix
    #./qutebrowser.nix
    #./swayidle.nix
    #./swaylock.nix
    ./waybar.nix
    #./wofi.nix
    #./zathura.nix
  ];


  home.packages = with pkgs; [
    bemenu
            #dbus-sway-environment
            #configure-gtk
            #wayland
            #xdg-utils # for opening default programs when clicking links
            #glib # gsettings
            #dracula-theme # gtk theme
            #gnome3.adwaita-icon-theme  # default gnome cursors
            #swaylock
            #swayidle
            #grim # screenshot functionality
            #slurp # screenshot functionality
            #wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
            #bemenu # wayland clone of dmenu
            #mako # notification system developed by swaywm maintainer
            #wdisplays # tool to configure displays

  ];
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;
    config = rec {
      bars = [
        {command = "${pkgs.waybar}/bin/waybar";}
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
        };
        DP-3 = {
          res = "1920x1080";
          pos = "1080,450";
        };
        DP-2 = {
          res = "1920x1080"; 
          pos = "3000,450";
        };
        "*" = { # change background for all outputs
          bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/synthwave-night-skyscrapers.jpg fill";
        };
      };
      # Use alacritty as default terminal
      terminal = "alacritty"; 
      startup = [
        # Launch alacritty on start
        {command = "alacritty";}
      ];
      menu = "bemenu-run";

      keybindings = {
        "${modifier}+f" = "exec maximize"; #custom script for zoom-fullscreen NOTWORKING?
        "${modifier}+Shift+f" = "fullscreen toggle";
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Alt+Space" = "exec brave";

        "${modifier}+Shift+q" = "kill";
        "${modifier}+q" = "exec kill-windows";
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
              "Alt+Shift+4" = "exec grimshot --notify save window";
              
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
              "${modifier}+s" = "layout stacking";
              "${modifier}+t" = "layout tabbed";

              #"${modifier}+o" = "inhibit_idle open; border normal; mark --add inhibiting_idle";
              #"${modifier}+Shift+o" = "inhibit_idle none; border pixel; unmark inhibiting_idle";

              #"${modifier}+j" = "exec ${pkgs.mako}/bin/makoctl invoke"; # Invoke default action on top notification.
              #"${modifier}+Shift+t" = "exec ${pkgs.flashfocus}/bin/flash_window";

              "${modifier}+${left}" = "focus left";
              "${modifier}+${down}" = "focus down";
              "${modifier}+${up}" = "focus up";
              "${modifier}+${right}" = "focus right";
              "${modifier}+Left" = "focus left";
              "${modifier}+Down" = "focus down";
              "${modifier}+Up" = "focus up";
              "${modifier}+Right" = "focus right";

              "${modifier}+Shift+${left}" = "move left";
              "${modifier}+Shift+${down}" = "move down";
              "${modifier}+Shift+${up}" = "move up";
              "${modifier}+Shift+${right}" = "move right";
              "${modifier}+Shift+Left" = "move left";
              "${modifier}+Shift+Down" = "move down";
              "${modifier}+Shift+Up" = "move up";
              "${modifier}+Shift+Right" = "move right";

              #"${modifier}+a" = "workspace back_and_forth";
              #"${modifier}+l" = "workspace prev";
              #"${modifier}+y" = "workspace next";
              #"${modifier}+Prior" = "workspace prev"; # PgUp
              #"${modifier}+Next" = "workspace next"; # PgDown
              "${modifier}+Ctrl+${left}" = "workspace prev";
              "${modifier}+Ctrl+${right}" = "workspace next";
              "${modifier}+Ctrl+Left" = "workspace prev";
              "${modifier}+Ctrl+Right" = "workspace next";

              # Move whole workspace to other output
              "${modifier}+Alt+${left}" = "move workspace to output left";
              "${modifier}+Alt+${down}" = "move workspace to output down";
              "${modifier}+Alt+${up}" = "move workspace to output up";
              "${modifier}+Alt+${right}" = "move workspace to output right";
              "${modifier}+Alt+Left" = "move workspace to output left";
              "${modifier}+Alt+Down" = "move workspace to output down";
              "${modifier}+Alt+Up" = "move workspace to output up";
              "${modifier}+Alt+Right" = "move workspace to output right";

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

              "${modifier}+Shift+1" = "move container to workspace number 1";
              "${modifier}+Shift+2" = "move container to workspace number 2";
              "${modifier}+Shift+3" = "move container to workspace number 3";
              "${modifier}+Shift+4" = "move container to workspace number 4";
              "${modifier}+Shift+5" = "move container to workspace number 5";
              "${modifier}+Shift+6" = "move container to workspace number 6";
              "${modifier}+Shift+7" = "move container to workspace number 7";
              "${modifier}+Shift+8" = "move container to workspace number 8";
              "${modifier}+Shift+9" = "move container to workspace number 9";
              "${modifier}+Shift+0" = "move container to workspace number 10";
            };
    };
      extraConfig = let inherit (config.colorscheme) colors; in /* swayfx specific config */ ''
                 set $mod Mod4
                 # Idle configuration
#
# Example configuration:
#
                 exec swayidle -w \
                         timeout 7320 'swaylock -f -c 000000' \
                         timeout 8000 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
                         before-sleep 'swaylock -f -c 000000'

# This will lock your screen after 300 seconds of inactivity, then turn off
# your displays after another 300 seconds, and turn your screens back on when
# resumed. It will also lock your screen before your computer goes to sleep.

### Input configuration
#
# Example configuration:
#
#   input "2:14:SynPS/2_Synaptics_TouchPad" {
#       dwt enabled
#       tap enabled
#       natural_scroll enabled
#       middle_emulation enabled
#   }
#
# You can get the names of your inputs by running: swaymsg -t get_inputs
# Read `man 5 sway-input` for more information about this section.
# Launch the network manager widget!
exec nm-applet

# Launch the bluetooth applet
exec blueman-applet

# Delayed launch of the bluetooth applet
exec "sleep 5 && blueman-applet"

# autotile!
exec autotiling

#exec "mako --config ~/.mako"

# STYLIZE!
gaps inner 10
corner_radius 10

# Window background blur
blur off
#blur_xray on
blur_passes 4
blur_radius 2

shadows on
#shadows_on_csd disable
shadow_blur_radius 10
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
