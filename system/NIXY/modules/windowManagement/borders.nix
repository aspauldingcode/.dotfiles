{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
in
{
  services.jankyborders = {
    enable = true;
    package = pkgs.callPackage ./../../customDerivations/borders.nix { };
    style = "round";
    order = "above";
    width = 2.0;
    background_color = "0xff${colors.base00}";
    hidpi = true;
    active_color = "0xff${colors.base07}";
    inactive_color = "0xff${colors.base05}";
    blacklist = [
      "google chrome"
      "vmware fusion"
      "xQuartz"
      "dmenu-mac"
      "unmenu"
      "X11.bin"
      "MacForge"
      "python3.11"
    ];
  };
}
