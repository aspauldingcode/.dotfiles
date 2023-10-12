{ lib, config, pkgs, ... }: 

{
  #You can import other home-manager modules here
  imports = [
    ./modules/NIXY/packages-NIXY.nix #which also calls the universal packages.
    #./modules/NIXY/yabai.nix
    #./modules/NIXY/skhd.nix
    #./modules/NIXY/spacebar.nix
    #./modules/NIXY/git.nix
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
      git = {
        enable = true;
        userName  = "aspauldingcode";
        userEmail = "aspauldingcode@gmail.com";
      };
      fish.enable = true;
      neovim = {
        enable = true;
        extraConfig = lib.fileContents ./modules/extraConfig/nvim/init.lua;
      };
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT BOOTLOADER!
  }


