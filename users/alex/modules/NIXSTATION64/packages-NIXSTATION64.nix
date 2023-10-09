{ lib, config, pkgs, ... }:

# NIXSTATION-specific packages
{
  imports = [
    ../packages-UNIVERSAL.nix
  ];
  home = {
    pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 22;
    };
    packages = with pkgs; [
    checkra1n
    android-studio
    corefonts
    beeper
    swayfx
    ];
  };
}

