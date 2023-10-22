{ lib, config, pkgs, ... }: 

{
  imports = [
    ./packages-NIXY.nix
    ./nvim.nix
    #./yabai.nix # FIXME UGH how do I home manager this?
    #./skhd.nix
    #./modules/NIXY/spacebar.nix
    ./git.nix
    #./modules/NIXY/fish.nix
    #./modules/NIXY/sketchybar.nix
  ];
      # You can place the 'home' and 'programs' sections within the 'config' attribute as follows:
      home = {
        username = "alex";
        homeDirectory = "/Users/alex";
        stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        file = { # MANAGE DOTFILES?
      };
    };

    programs = {
      home-manager.enable = true;
      #git = {
      #  enable = true;
      #  userName  = "aspauldingcode";
      #  userEmail = "aspauldingcode@gmail.com";
      #};

      fish.enable = true;
    };
  }
