{ home-manager, lib, config, pkgs, nix-colors, ... }: 

# let
#   android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
# in
  {
    imports = [
      nix-colors.homeManagerModules.default
      ./packages-NIXY.nix
      #./../extraConfig/nvim/nixvim.nix
      ./alacritty.nix
      ./git.nix
      ./fish.nix
      ./zsh.nix
      ./karabiner.nix
      ./cava.nix
      ./zellij.nix
      ./sketchybar/sketchybar.nix 
      ./yabai.nix # contains skhd and borders config.
      ./phoenix.nix # new window-manager for macOS!
    ];

    #colorScheme = nix-colors.colorSchemes.dracula;
    #colorScheme = nix-colors.colorSchemes.paraiso;
    colorScheme = nix-colors.colorSchemes.gruvbox-dark-soft;

    home = {
      username = "alex";
      homeDirectory = lib.mkForce "/Users/alex";
      stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      shellAliases = { 
        python = "python3.11";
        #vim = "nvim";
        #vi = "nvim";
        reboot = "sudo reboot now";
        rb = "sudo reboot now";
        shutdown = "sudo shutdown -h now";
        sd = "sudo shutdown -h now";
        l = "ls";
      };
    };

  # Enable nix flakes and nix command?
  #nix = {
   # package = pkgs.nix;
   # settings.experimental-features = [ "nix-command" "flakes" ];
  #};

  programs = { 
    # allow Home-Manager to configure itself
    home-manager.enable = true;
    ssh.addKeysToAgent = true;
  };
}
