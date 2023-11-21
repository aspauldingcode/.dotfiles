{ lib, config, pkgs, nix-colors, ... }: 

let
  android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
in
  {
    imports = [
      nix-colors.homeManagerModules.default
      ./packages-NIXY.nix
      ./nvim.nix
      ./alacritty.nix
      ./git.nix
      ./fish.nix
      ./zsh.nix
      ./karabiner.nix
      #./zellij
      ./sketchybar/sketchybar.nix 
      ./yabai.nix # contains skhd and borders config.
    ];

    #colorScheme = nix-colors.colorSchemes.dracula;
    #colorScheme = nix-colors.colorSchemes.paraiso;
    colorScheme = nix-colors.colorSchemes.gruvbox-dark-soft;

    home = {
      username = "alex";
      homeDirectory = "/Users/alex";
      stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      shellAliases = { 
        python = "python3.11";
        vim = "nvim";
        vi = "nvim";
        reboot = "sudo reboot now";
        rb = "sudo reboot now";
        shutdown = "sudo shutdown -h now";
        sd = "sudo shutdown -h now";
        l = "ls";
      };
      file = { # MANAGE DOTFILES?
    };
  };
  programs = {
    home-manager.enable = true; 
  };
}
