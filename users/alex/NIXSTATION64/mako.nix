{ config, ... }:

{
  services.mako = {
    enable = true;
    maxVisible = -1;
    output = "DP-2";
    layer = "overlay";
    anchor = "top-right";
    borderSize = 2;
    borderColor = "#${config.colorScheme.colors.base07}";
    borderRadius = 8;
    defaultTimeout = 5000;
    ignoreTimeout = false;
    backgroundColor = "#${config.colorScheme.colors.base00}E6";
  };
}
