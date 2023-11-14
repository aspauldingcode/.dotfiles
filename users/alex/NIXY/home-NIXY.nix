{ lib, config, pkgs, ... }: 

let
  android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
in
  {
    imports = [
      ./packages-NIXY.nix
      ./nvim.nix
      ./alacritty.nix
      ./git.nix
      ./fish.nix
      #./zellij
      ./yabai.nix # FIXME UGH how do I home manager this?
    #./skhd.nix
    #./sketchybar.nix
  ];
  home = {
    username = "alex";
    homeDirectory = "/Users/alex";
    stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    shellAliases = { 
      python3 = "python3.11"; 
    };
    file = { # MANAGE DOTFILES?
    };
  };
  programs = {
    home-manager.enable = true; 
  };
}
