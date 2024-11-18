{ config, pkgs, ... }:

let
  inherit (config.colorScheme) palette;
in
{
  services.jankyborders = {
    enable = true;
    package = pkgs.callPackage ./../../customDerivations/borders.nix { };
    order = "above";
    style = "round";
    width = 2.0;
    background_color = "0xff${palette.base00}";
    hidpi = true;
    active_color = "0xff${palette.base07}";
    inactive_color = "0xff${palette.base05}";
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
