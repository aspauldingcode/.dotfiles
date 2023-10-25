{ lib, config, pkgs, ...}:

{
 wayland.windowManager.sway = {
   enable = true;
   package = with pkgs [
    bemenu
    waybar
    swayfx
   ];
    config = rec {
      modifier = "Mod4";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      output = {
        DP-4 = { 
          res = "1920x1080";
          pos = "0,0"; 
          transform = 270;
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
          bg = "../../extraConfig/wallpapers/synthwave-night-skyscrapers.jpg";
        };
      }
      
      # Use alacritty as default terminal
      terminal = "alacritty"; 
      startup = [
        # Launch Brave on start
        {command = "brave";}
      ];
    };
  };
}
