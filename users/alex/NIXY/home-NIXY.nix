{
  lib,
  nix-colors,
  config,
  ...
}:

# let
#   android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
# in
{
  imports = [
    nix-colors.homeManagerModules.default
    ./scripts-NIXY.nix
    # ./../extraConfig/nvim/nixvim.nix # FIXME: BROKEN atm
    ./../universals/modules/firefox.nix
    ./../universals/modules/cursor.nix # vscode with ai
    ./../universals/modules/discord.nix
    ./../universals/modules/shells.nix
    ./../universals/modules/btop.nix
    ./../universals/modules/git.nix
    ./modules/theme.nix
    ./modules/xcode/xcode.nix # FIXME: use nix-color theme
    ./modules/alacritty.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/maco.nix
    ./modules/packages-NIXY.nix
    ./modules/instantview.nix
    ./modules/karabiner.nix
    ./modules/cava.nix
    ./modules/xinit.nix
    ./modules/i3.nix
    ./modules/qutebrowser.nix
    ./modules/sketchybar/sketchybar.nix
    ./modules/yabai.nix # contains skhd and borders config.
    ./modules/phoenix/phoenix.nix # new window-manager for macOS!
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
    notificationcenter = {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/launchctl"
          "unload"
          "-w"
          "/System/Library/LaunchAgents/com.apple.notificationcenterui.plist"
        ];
        RunAtLoad = true;
        StandardOutPath = "/dev/null";
        StandardErrorPath = "/dev/null";
      };
    };
  };
}
