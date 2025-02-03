{ config, pkgs, ... }:

{
  services.sketchybar = {
    enable = true; # Whether to enable sketchybar.
    package = pkgs.unstable.sketchybar; # The sketchybar package to use.
    # config = ''

    # '';
    extraPackages = [
      pkgs.jq
      pkgs.gcal
    ]; # Extra packages to add to PATH. Example: [ pkgs.jq ]
  };
}
