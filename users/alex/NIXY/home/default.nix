{
  lib,
  username,
  ...
}:
{
  home = {
    stateVersion = "25.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    homeDirectory = lib.mkForce "/Users/${username}";
    shellAliases = {
      python = "python3.12";
    };
    # Mousecape cursor configuration removed
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

    # Warning dialog at 8:25 PM
    shutdown-warning = {
      enable = true;
      config = {
        Program = "/usr/bin/osascript";
        ProgramArguments = [
          "/usr/bin/osascript"
          "-e"
          "display dialog \"Your Mac will shut down in 5 minutes at 8:30 PM\" with title \"Shutdown Warning\" buttons {\"OK\"} default button \"OK\" with icon caution"
        ];
        StartCalendarInterval = {
          Hour = 20;
          Minute = 25;
        };
        StandardErrorPath = "/dev/null";
        StandardOutPath = "/dev/null";
      };
    };

    # Immediate shutdown at 8:30 PM
    auto-shutdown = {
      enable = true;
      config = {
        Program = "/sbin/shutdown";
        ProgramArguments = [
          "/sbin/shutdown"
          "-h"
          "now"
        ];
        StartCalendarInterval = {
          Hour = 20;
          Minute = 30;
        };
        StandardErrorPath = "/dev/null";
        StandardOutPath = "/dev/null";
      };
    };
  };
}
