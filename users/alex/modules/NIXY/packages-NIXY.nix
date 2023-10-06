{ lib, config, pkgs, ... }:

# NIXY-specific packages
{
  imports = [
    ../packages-UNIVERSAL.nix
  ];
  home.packages = with pkgs; [ 
    # dmenu-mac
    # yabai?
    # skhd?
    # macports?
    # orbstack?
    # UTM? 
    # xCode?
    # x-code-cli?
    # Townscraper?
    # homebrew?
    # sketchybar?
    # xinit?
    # xorg-server?
    # XQuartz?
    ];
  };
}

