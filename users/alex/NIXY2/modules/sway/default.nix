{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # ./waybar.nix
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = lib.mkForce false;
    config = rec {
      bars = [ ];
      modifier = "Mod4";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      # Assign workspaces to outputs
      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "Ancor Communications Inc VE248 G1LMQS085722";
        }
        {
          workspace = "2";
          output = "Ancor Communications Inc ASUS VE278 JCLMTF141603";
        }
        {
          workspace = "3";
          output = "Ancor Communications Inc ASUS VE278 J7LMTF164099";
        }
      ];
      output = {
        "Ancor Communications Inc VE248 G1LMQS085722" = {
          res = "1920x1080";
          pos = "0,0";
          transform = "270";
        };
        "Ancor Communications Inc ASUS VE278 JCLMTF141603" = {
          res = "1920x1080";
          pos = "1080,450";
        };
        "Ancor Communications Inc ASUS VE278 J7LMTF164099" = {
          res = "1920x1080";
          pos = "3000,450";
        };
        "*" = {
          # change background for all outputs
          bg = "~/.dotfiles/users/alex/extraConfig/wallpapers/gruvbox-nix.png fill";
        };
      };
      # Use alacritty as default terminal
      terminal = "alacritty";
      startup = [
        # Launch alacritty on start
        { command = "alacritty"; }
      ];
      menu = "bemenu-run";
      window.titlebar = false;
      floating.titlebar = false;
      workspaceLayout = "default";
      keybindings = {
        "${modifier}+f" = "exec maximize"; # custom script for zoom-fullscreen NOTWORKING?
        "${modifier}+Shift+f" = "fullscreen toggle";
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Alt+Space" = "exec firefox";
        "${modifier}+Shift+Alt+Space" = "exec firefox -private-window";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+q" = "exec wtype -M ctrl -P w -m ctrl -p w";
        "${modifier}+a" = "exec show-all-windows";
        "${modifier}+d" = "exec ${menu}";
        "${modifier}+m" = "exec toggle-waybar";

        # Brightness keys
        "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
        "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";

        "Control+Alt+Delete" = "exec sudo systemctl reboot";
        "Control+Shift+Alt+Delete" = "exec sudo systemctl poweroff";

        # Screenshot
        "Alt+Shift+3" = "exec screenshot"; # All visible outputs
        "Alt+Shift+4" =
          ''exec grimshot --notify save anything ~/Desktop/"Screenshot $(date '+%Y-%m-%d at %I.%M.%S %p').png"'';

        "${modifier}+Control+Shift+r" = "exec swaymsg output '*' disable && swaymsg output '*' enable";
        "${modifier}+Shift+Ctrl+minus" = "move scratchpad"; # Change to control alt down
        "${modifier}+Shift+Ctrl+equal" = "scratchpad show"; # change to control alt up

        "${modifier}+r" = "exec python3.11 ~/.dotfiles/i3-tools-master/rotate_layout.py 0 -m -f"; # ??? orrresize mode

        "${modifier}+Shift+Space" =
          "floating toggle ; [floating] resize set 81ppt 81ppt ; move position center";
        "${modifier}+Space" = "focus mode_toggle";
        "${modifier}+u" = "focus parent";

        "${modifier}+w" = "layout toggle split";
        "${modifier}+s" = "layout tabbed"; # macos is stacked layout
        "${modifier}+e" = "layout default";

        "${modifier}+b" = "split horizontal"; # when toggled will preview the right screen like it will with mouse modifier
        "${modifier}+v" = "split vertical"; # when toggled will preview the lower screen like it will with mouse modifier

        # Change focused window
        "${modifier}+${left}" = "focus left";
        "${modifier}+${down}" = "focus down";
        "${modifier}+${up}" = "focus up";
        "${modifier}+${right}" = "focus right";
        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";

        #FIXME: Try NOT to swap a floating window?
        # Move windows (swap if tiled, move 20px if floating
        "${modifier}+Shift+Left" =
          ''mark --add "_swap", focus left, swap container with mark "_swap", focus left, unmark "_swap"; [floating con_id="__focused__"] move left 20px'';
        "${modifier}+Shift+Down" =
          ''mark --add "_swap", focus down, swap container with mark "_swap", focus down, unmark "_swap"; [floating con_id="__focused__"] move down 20px'';
        "${modifier}+Shift+Up" =
          ''mark --add "_swap", focus up, swap container with mark "_swap", focus up, unmark "_swap"; [floating con_id="__focused__"] move up 20px'';
        "${modifier}+Shift+Right" =
          ''mark --add "_swap", focus right, swap container with mark "_swap", focus right, unmark "_swap"; [floating con_id="__focused__"] move right 20px'';

        # Navigate to next/prev workspace
        "${modifier}+Ctrl+${left}" = "workspace prev";
        "${modifier}+Ctrl+${down}" = "workspace next";
        "${modifier}+Ctrl+${up}" = "workspace prev";
        "${modifier}+Ctrl+${right}" = "workspace next";
        "${modifier}+Ctrl+Left" = "workspace prev";
        "${modifier}+Ctrl+Down" = "workspace next";
        "${modifier}+Ctrl+Up" = "workspace prev";
        "${modifier}+Ctrl+Right" = "workspace next";

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

        "${modifier}+Alt+${left}" = "resize grow left 20px";
        "${modifier}+Alt+${down}" = "resize grow down 20px";
        "${modifier}+Alt+${up}" = "resize grow up 20px";
        "${modifier}+Alt+${right}" = "resize grow right 20px";
        "${modifier}+Alt+Left" = "resize grow left 20px";
        "${modifier}+Alt+Down" = "resize grow down 20px";
        "${modifier}+Alt+Up" = "resize grow up 20px";
        "${modifier}+Alt+Right" = "resize grow right 20px";

        "${modifier}+Alt+Shift+${left}" = "resize shrink left 20px";
        "${modifier}+Alt+Shift+${down}" = "resize shrink down 20px";
        "${modifier}+Alt+Shift+${up}" = "resize shrink up 20px";
        "${modifier}+Alt+Shift+${right}" = "resize shrink right 20px";
        "${modifier}+Alt+Shift+Left" = "resize shrink left 20px";
        "${modifier}+Alt+Shift+Down" = "resize shrink down 20px";
        "${modifier}+Alt+Shift+Up" = "resize shrink up 20px";
        "${modifier}+Alt+Shift+Right" = "resize shrink right 20px";

        "${modifier}+g" = "exec toggle-gaps";

        "${modifier}+Shift+R" = "exec fix-wm";
      };
    };

    extraConfig =
      let
        inherit (config.colorscheme) colors;
      in
      ''
        set $mod Mod4

        # Idle configuration
        exec swayidle -w \
        timeout 120 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
        timeout 300 'swaylock -f -c 000000' \
        before-sleep 'swaylock -f -c 000000'

        exec --no-startup-id gammastep # enable gammastep server

        # You can get the names of your inputs by running: swaymsg -t get_inputs
        # Read `man 5 sway-input` for more information about this section.
        exec --no-startup-id 'nm-applet --indicator'

        # Launch the bluetooth applet
        exec blueman-applet

        # Delayed launch of the bluetooth applet
        exec "sleep 5 && blueman-applet"

        # autotile!
        exec autotiling

        # way-displays: Auto Manage Your Wayland Displays
        exec way-displays > /tmp/way-displays.''${XDG_VTNR}.''${USER}.log 2>&1

        ## FLOAT WINDOWS FROM THE TREE!!
        for_window [app_id="firefox" title="Picture-in-Picture"] floating enable, sticky enable

        # STYLIZE!
        gaps inner 10
        gaps top -2
        corner_radius 8

        #FIX waybar tooltips!
        for_window [app_id="waybar" floating] {
          move position cursor
          move down 120px # adjust if some menus still don't fit
        }

        # Fix scrolling on apple trackpad!
        input "1452:641:Apple_Internal_Keyboard_/_Trackpad" {
          left_handed disabled
          tap disabled
          natural_scroll enabled
          dwt disabled # allow touchpad while typing
          accel_profile "flat" # disable mouse acceleration (enabled by default; to set it manually, use "adaptive" instead of "flat")
          pointer_accel 0.8 # set mouse sensitivity (between -1 and 1)
          scroll_factor 0.2 # adjust scroll speed; set to your preferred value
        }

        # Enable csd borders # options are: none | normal | csd | pixel [<n>]
        bindsym $mod+Shift+B exec swaymsg border toggle

        #for all windows, brute-force use of "pixel"
        for_window [shell="xdg_shell"] border pixel 2
        for_window [shell="xwayland"] border pixel 2

        # HIDE CURSOR AUTOMATICALLY
        seat * hide_cursor 8000

        # HIDE TITLEBAR!
        # SET BORDER TO 2 PIXELS!
        default_border pixel 2
        default_floating_border pixel 2
        client.unfocused ${colors.base05} ${colors.base05} ${colors.base05} ${colors.base05}
        client.focused_inactive ${colors.base05} ${colors.base05} ${colors.base05} ${colors.base05}
        client.focused ${colors.base07} ${colors.base07} ${colors.base07} ${colors.base07}

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
