{ home-manager, lib, config, pkgs, nix-colors, ... }: 

# let
#   android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
# in
  {
    imports = [
      nix-colors.homeManagerModules.default
      ./packages-NIXY.nix
      ./../extraConfig/nvim/nixvim.nix
      ./theme.nix
      ./xcode/xcode.nix #FIXME: use nix-color theme
      ./alacritty.nix
      ./kitty.nix
      ./yazi/yazi.nix
      ./betterdiscord.nix
      ./git.nix
      ./fish.nix
      ./zsh.nix
      ./karabiner.nix
      ./cava.nix
      #./zellij.nix
      ./btop.nix
      ./xinit.nix
      ./i3.nix
      ./sketchybar/sketchybar.nix 
      ./yabai.nix # contains skhd and borders config.
      #./phoenix/phoenix.nix # new window-manager for macOS!
    ];

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

  # disable Volumw/Brightness HUD on macOS at login!
  launchd.agents.xdg_cache_home = {
    enable = true;
    config = {
      Program = "/bin/launchctl";
      ProgramArguments = [ 
        "/bin/launchctl" "unload" "-F"
        "/System/Library/LaunchAgents/com.apple.OSDUIHelper.plist" 
      ];
      RunAtLoad = true;
      StandardErrorPath = "/dev/null";
      StandardOutPath = "/dev/null";
    };
  };

  programs = { 
    # allow Home-Manager to configure itself
    home-manager.enable = true;
    ssh.addKeysToAgent = true;
  };
}
