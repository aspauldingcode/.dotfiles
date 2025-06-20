{
  lib,
  config,
  pkgs,
  ...
}:

# let
#   android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
# in
{
  home = {
    stateVersion = "24.11"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    shellAliases = {
      python = "python3.12";
    };
    file."Library/Application Support/Mousecape/capes" = {
      target = "Library/Application Support/Mousecape/capes/";
      source = ../../extraConfig/cursors-macOS;
    };
  };

  programs = {
    # allow Home-Manager to configure itself
    home-manager.enable = true;
    ssh = {
      enable = true;
      addKeysToAgent = "yes";

      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
      };
    };
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
