{
  lib,
  nix-colors,
  config,
  pkgs,
  ...
}:

# let
#   android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
# in
{
  imports = [
    nix-colors.homeManagerModules.default
    ./scripts-NIXY.nix
    ./../extraConfig/nvim/nixvim.nix # FIXME: BROKEN atm
    ./../universals/modules/firefox.nix
    ./../universals/modules/cursor.nix # vscode with ai
    ./../universals/modules/discord.nix
    ./../universals/modules/shells.nix
    ./../universals/modules/btop.nix
    ./../universals/modules/git.nix
    ./../universals/modules/yazi.nix
    ./../universals/modules/okular.nix
    ./../universals/modules/fastfetch.nix

    ./modules/theme.nix
    ./modules/xcode/xcode.nix # FIXME: use nix-color theme
    ./modules/alacritty.nix
    ./modules/kitty.nix
    ./modules/maco.nix
    ./modules/unmenu.nix
    ./modules/unmenu-configured.nix
    ./modules/packages-NIXY.nix
    ./modules/instantview.nix
    ./modules/karabiner.nix
    ./modules/spicetify/spicetify.nix
    ./modules/cava.nix
    ./modules/xinit.nix
    ./modules/colors.nix # generate a color palette from nix-colors (to view all colors in a file!)
    ./modules/i3.nix
    ./modules/macwmfx.nix
    ./modules/qutebrowser.nix
    ./modules/sketchybar/sketchybar.nix
  ];

  home = {
    username = "alex";
    homeDirectory = lib.mkForce "/Users/alex";
    stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    shellAliases = {
      python = "python3.11";
      #vim = "nvim";
      #vi = "nvim";
      l = "ls";
    };
    file."Library/Application Support/Mousecape/capes" = {
      target = "Library/Application Support/Mousecape/capes/";
      source = ../extraConfig/cursors-macOS;
    };
  };

  programs = {
    # allow Home-Manager to configure itself
    home-manager.enable = true;
    ssh.addKeysToAgent = true;
  };

  # disable Volume/Brightness HUD on macOS at login!
  launchd.agents = { 
    xdg_cache_home = {
      enable = true;
      config = {
        Program = "/bin/launchctl";
        ProgramArguments = [
          "/bin/launchctl"
          "unload"
          "-F"
          "/System/Library/LaunchAgents/com.apple.OSDUIHelper.plist"
        ];
        RunAtLoad = true;
        StandardErrorPath = "/dev/null";
        StandardOutPath = "/dev/null";
      };
    };
  };
}
