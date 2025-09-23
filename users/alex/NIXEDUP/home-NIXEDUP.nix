{
  ...
}:
{
  #You can import other home-manager modules here
  imports = [
    ./modules/NIXSTATION/packages-NIXEDUP.nix
  ];
  # Configure your nixpkgs instance
  config = {
    allowUnfree = true; # Enable Unfree
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = _: true; # Still open ticket as of: 10/04/23.

    # You can place the 'home' and 'programs' sections within the 'config' attribute as follows:
    home = {
      username = "alex"; # NIXEDUP is special - keep hardcoded for mobile
      homeDirectory = "/home/alex"; # NIXEDUP is special - keep hardcoded for mobile
      stateVersion = "25.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      file = {
        # MANAGE DOTFILES?
      };
    };

    programs = {
      home-manager.enable = true;
      git = {
        enable = true;
        userName = "aspauldingcode";
        userEmail = "aspauldingcode@gmail.com";
      };
      fish.enable = true;
      neovim = {
        enable = true;
        #extraConfig = lib.fileContents ../../extraConfig/nvim/init.lua;
      };
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT BOOTLOADER!
  };
}
