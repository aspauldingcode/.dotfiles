{
  lib,
  config,
  pkgs,
  username,
  ...
}: {
  home = {
    stateVersion = "25.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    homeDirectory = lib.mkForce "/Users/${username}";
    shellAliases = {
      python = "python3.12";
    };
  };

  programs = {
    # allow Home-Manager to configure itself
    home-manager.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
        };
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
