{ pkgs, ... }:

# i3 configuration for NIXY macOS on xQuartz.app!
{
  xdg.configFile.i3 = {
    target = "i3/config";
    text = ''
      #if using bindcode instead of bindsym:
      #code 63 is command. 
      #code 64 is shift.
      #code 67 is control.
      #code 57 is space.
      #code 44 is return.

      ### Variables for settings (This makes changing them WAY easier!) ###
      set $mod                             Mod1
      set $smod                            Shift
      set $wm_setting_font                 pango:Source JetBrains Mono, Regular 12
      set $wm_setting_gap_width            15
      set $wm_setting_gap_heigth           15
      set $wm_setting_border_size          3
      set $wm_setting_key_left             Left
      set $wm_setting_key_down             Down
      set $wm_setting_key_up               Up
      set $wm_setting_key_right            Right

      # using macOS by the way!!!
      set $wm_setting_app_terminal         xterm
      set $wm_setting_app_browser          open -na "Brave Browser"
      # set $wm_setting_app_launcher         /opt/local/bin/dmenu_run
      # set $wm_setting_app_compositor       picom

      set $wm_color_border_active_bg       #81A1C1
      set $wm_color_border_active_fg       #3B4252
      set $wm_color_border_inactive_bg     #3B4252
      set $wm_color_border_inactive_fg     #D8DEE9
      set $wm_color_background             #2E3440

      set $bar_setting_position            top
      set $bar_setting_mode                dock # dock|hide|invisible|toggle
      #set $bar_setting_font                pango:Source JetBrains Mono, Regular 12
      set $bar_setting_separator           " - "
      set $bar_setting_statusCommand       i3status
      set $bar_setting_trayoutput          full

      set $bar_color_background            #3B4252
      set $bar_color_foreground            #D8DEE9
      set $bar_color_statusline            #D8DEE9
      set $bar_color_separator             #D8DEE9

      set $bar_color_workspace_focused_bg  #A3BE8C
      set $bar_color_workspace_focused_fg  #2E3440
      set $bar_color_workspace_active_bg   #EBCB8B
      set $bar_color_workspace_active_fg   #2E3440
      set $bar_color_workspace_inactive_bg #BF616A
      set $bar_color_workspace_inactive_fg #2E3440
      set $bar_color_workspace_urgent_bg   #D08770
      set $bar_color_workspace_urgent_fg   #2E3440

      # ### Applications ###
      # # Start a terminal emulator
      bindsym $mod+Return exec $wm_setting_app_terminal

      # # Start a web browser
      bindsym $mod+Mod3+Space exec $wm_setting_app_browser

      # # Start a program launcher
      bindsym $mod+d exec /opt/local/bin/dmenu_run

      # # Run a window compositor (for effects like transparency or full VSync)
      # exec_always --no-startup-id $wm_setting_app_compositor

      # ### Workspaces ### 
      # NOTE: Might need to use yabai for this! Using macOS by the way.
      set $ws1  "1"
      set $ws2  "2"
      set $ws3  "3"
      set $ws4  "4"
      set $ws5  "5"
      set $ws6  "6"
      set $ws7  "7"
      set $ws8  "8"
      set $ws9  "9"
      set $ws10 "10"

      # # Switch to workspace n
      bindsym $mod+1 workspace $ws1
      bindsym $mod+2 workspace $ws2
      bindsym $mod+3 workspace $ws3
      bindsym $mod+4 workspace $ws4
      bindsym $mod+5 workspace $ws5
      bindsym $mod+6 workspace $ws6
      bindsym $mod+7 workspace $ws7
      bindsym $mod+8 workspace $ws8
      bindsym $mod+9 workspace $ws9
      bindsym $mod+0 workspace $ws10

      # # Move focused container to workspace n            
      bindsym $mod+$smod+1 move container to workspace $ws1, workspace number $ws1, exec "yabai -m window --space 1; yabai -m space --focus 1"
      bindsym $mod+$smod+2 move container to workspace $ws2, workspace number $ws2, exec "yabai -m window --space 2; yabai -m space --focus 2"
      bindsym $mod+$smod+3 move container to workspace $ws3, workspace number $ws3, exec "yabai -m window --space 3; yabai -m space --focus 3"
      bindsym $mod+$smod+4 move container to workspace $ws4, workspace number $ws4, exec "yabai -m window --space 4; yabai -m space --focus 4"
      bindsym $mod+$smod+5 move container to workspace $ws5, workspace number $ws5, exec "yabai -m window --space 5; yabai -m space --focus 5"
      bindsym $mod+$smod+6 move container to workspace $ws6, workspace number $ws6, exec "yabai -m window --space 6; yabai -m space --focus 6"
      bindsym $mod+$smod+7 move container to workspace $ws7, workspace number $ws7, exec "yabai -m window --space 7; yabai -m space --focus 7"
      bindsym $mod+$smod+8 move container to workspace $ws8, workspace number $ws8, exec "yabai -m window --space 8; yabai -m space --focus 8"
      bindsym $mod+$smod+9 move container to workspace $ws9, workspace number $ws9, exec "yabai -m window --space 9; yabai -m space --focus 9"
      bindsym $mod+$smod+0 move container to workspace $ws10, workspace number $ws10, exec "yabai -m window --space 10; yabai -m space --focus 10"

      # ### Window sizes and positions ###
      # # Cange focus
      bindsym $mod+$wm_setting_key_left        focus left
      bindsym $mod+$wm_setting_key_down        focus down
      bindsym $mod+$wm_setting_key_up          focus up
      bindsym $mod+$wm_setting_key_right       focus right

      # # Move focused window
      # Move and swap windows, with special handling for floating windows
      bindsym $mod+Shift+Left mark --add "_swap", focus left, swap container with mark "_swap", focus left, unmark "_swap", [floating con_id="__focused__"] move left 20px
      bindsym $mod+Shift+Down mark --add "_swap", focus down, swap container with mark "_swap", focus down, unmark "_swap", [floating con_id="__focused__"] move down 20px
      bindsym $mod+Shift+Up mark --add "_swap", focus up, swap container with mark "_swap", focus up, unmark "_swap", [floating con_id="__focused__"] move up 20px
      bindsym $mod+Shift+Right mark --add "_swap", focus right, swap container with mark "_swap", focus right, unmark "_swap", [floating con_id="__focused__"] move right 20px

      # # Resize window (you can also use the mouse for that)
      # mode "resize" {
      # #	These bindings trigger as soon as you enter the resize mode
      #
      # #	Pressing left will shrink the window’s width.
      # #	Pressing right will grow the window’s width.
      # #	Pressing up will shrink the window’s height.
      # #	Pressing down will grow the window’s height.
      #         bindsym $wm_setting_key_left  resize shrink width 10 px or 10 ppt
      #         bindsym $wm_setting_key_down  resize grow height 10 px or 10 ppt
      #         bindsym $wm_setting_key_up    resize shrink height 10 px or 10 ppt
      #         bindsym $wm_setting_key_right resize grow width 10 px or 10 ppt
      #
      # #	Resize the gap width and height
      #         bindsym $smod+$wm_setting_key_left  gaps horizontal minus 5
      #         bindsym $smod+$wm_setting_key_down  gaps horizontal plus 5
      #         bindsym $smod+$wm_setting_key_up    gaps vertical minus 5
      #         bindsym $smod+$wm_setting_key_right gaps vertical plus 5

      # #	Back to normal: Enter or Escape or $mod+r
      #         bindsym Return mode "default"
      #         bindsym Escape mode "default"
      #         bindsym $mod+r mode "default"
      # }

      # bindsym $mod+r mode "resize"

      # ### Gaps (Requires i3 version 4.22 and above!) ###
      # gaps horizontal $wm_setting_gap_width
      # gaps vertical   $wm_setting_gap_heigth
      # smart_gaps on

      # ### Borders ###
      # default_border pixel $wm_setting_border_size
      # default_floating_border pixel $wm_setting_border_size
      # smart_borders on

      # ### Colors ###
      # # class                 border                       background                   text                         indicator                    child_border
      # client.focused          $wm_color_border_active_bg   $wm_color_border_active_bg   $wm_color_border_active_fg   $wm_color_border_active_bg   $wm_color_border_active_bg
      # client.focused_inactive $wm_color_border_inactive_bg $wm_color_border_inactive_bg $wm_color_border_inactive_fg $wm_color_border_inactive_bg $wm_color_border_inactive_bg
      # client.unfocused        $wm_color_border_inactive_bg $wm_color_border_inactive_bg $wm_color_border_inactive_fg $wm_color_border_inactive_bg $wm_color_border_inactive_bg
      # client.urgent           $wm_color_border_inactive_bg $wm_color_border_inactive_bg $wm_color_border_inactive_fg $wm_color_border_inactive_bg $wm_color_border_inactive_bg
      # client.placeholder      $wm_color_border_inactive_bg $wm_color_border_inactive_bg $wm_color_border_inactive_fg $wm_color_border_inactive_bg $wm_color_border_inactive_bg
      # client.background       $wm_color_background

      # ### i3bar ###
      # bar {
      #         position         $bar_setting_position
      #         mode             $bar_setting_mode
      #         font             $bar_setting_font
      #         separator_symbol $bar_setting_separator
      #         status_command   $bar_setting_statusCommand
      #         tray_output      $bar_setting_trayoutput
      #
      #         colors {
      #                 background   $bar_color_background
      #                 statusline   $bar_color_statusline
      #                 separator    $bar_color_separator
      #
      #                 focused_workspace  $bar_color_workspace_focused_bg  $bar_color_workspace_focused_bg  $bar_color_workspace_focused_fg
      #                 active_workspace   $bar_color_workspace_active_bg   $bar_color_workspace_active_bg   $bar_color_workspace_active_fg
      #                 inactive_workspace $bar_color_workspace_inactive_bg $bar_color_workspace_inactive_bg $bar_color_workspace_inactive_fg
      #                 urgent_workspace   $bar_color_workspace_urgent_bg   $bar_color_workspace_urgent_bg   $bar_color_workspace_urgent_fg
      #         }
      # }

      # ### Miscellaneous settings ###
      # # Set the font used for titlebars (which are hidden here)
      font $wm_setting_font

      # # Use Mouse+$mod to drag floating windows to their wanted position (Mod2, like yabai!)
      floating_modifier Mod1

      # # Enter fullscreen mode for the focused window
      bindsym $mod+$smod+f fullscreen toggle

      # # Toggle between tiling and floating
      bindsym $mod+$smod+space floating toggle

      # # Kill the focused window
      bindsym $mod+$smod+q kill

      # # Restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
      bindsym $mod+$smod+r restart

      # # Exit i3 (logs you out of your X session)
      # bindsym $mod+$smod+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

      #autotile using autotiling: (requires it to be compiled for aarch64-darwin!)
      #exec autotiling
      exec "/opt/local/bin/python3.11 ~/.dotfiles/i3ipc-python-master/autotiling.py"
      bindsym $mod+g exec "/opt/local/bin/python3.11 ~/.dotfiles/i3ipc-python-master/autotiling.py"

      # auto split v/h
      #for_window [class=.*] layout toggle split
      #bindsym $mod+Shift+q i3-msg kill && i3-msg layout toggle split
    '';
  };
}
