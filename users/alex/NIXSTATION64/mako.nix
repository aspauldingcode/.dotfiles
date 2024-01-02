{ config, ... }:

{
  services.mako = {
    enable = true;
    maxVisible = -1;
    output = "DP-2";
    layer = "overlay";
    anchor = "top-right";
    borderSize = 2;
    borderColor = "#${config.colorScheme.colors.base00}";
    borderRadius = 10;
    defaultTimeout = 5000;
    ignoreTimeout = false;
    backgroundColor = "#282828";
  };
}
