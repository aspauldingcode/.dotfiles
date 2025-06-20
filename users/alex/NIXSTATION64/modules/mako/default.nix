{ config, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      max-visible = -1;
      output = "DP-6";
      layer = "overlay";
      anchor = "top-right";
      border-size = 2;
      border-color = "#${config.colorscheme.colors.base07}";
      border-radius = 8;
      default-timeout = 5000;
      ignore-timeout = false;
      background-color = "#${config.colorscheme.colors.base00}E6";
    };
  };
}
