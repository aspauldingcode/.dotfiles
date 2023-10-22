{ config, lib, pkgs, ... }:

{
  services.mako = {
    enable = true;
    maxVisible = -1;
    output = "DP-2";
    layer = "overlay";
    anchor = "top-right";
    borderSize = 2;
    borderColor = "#A34A28";
    borderRadius = 10;
    defaultTimeout = 5000;
    ignoreTimeout = false;
    backgroundColor = "#282828";
  };
}
