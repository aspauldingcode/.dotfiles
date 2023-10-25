{ lib, config, pkgs, ...}:

{
  services.redshift = {
    enable = true;
    #package = pkgs.redshift-wlr;
    settings.redshift = {
      brightness-day = "1";
      brightness-night = "1";
    };
    latitude = "46.87";
    longitude = "113.99";
    temperature = {
      day = 6500;
      night = 3500;
    };
  };
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;
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
        # Launch Brave on start
        {command = "brave";}
      ];
    };
  };
}
