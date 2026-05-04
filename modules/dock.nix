{
  flake.modules.darwin.dock = { config, lib, pkgs, ... }: {
    options.dendritic.dock.apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Ordered list of .app paths to pin in the Dock.";
    };

    config = {
      # System apps appear first in the dock
      dendritic.dock.apps = lib.mkBefore [
        "/System/Library/CoreServices/Finder.app"
        "/System/Applications/Apps.app"
        "/Applications/Safari.app"
      ];

      system = {
        defaults.dock = {
          autohide = true;
          expose-animation-duration = 0.1;
          orientation = "bottom";
          show-recents = false;
          showhidden = true;
          wvous-bl-corner = 1;
          wvous-br-corner = 1;
          wvous-tl-corner = 1;
          wvous-tr-corner = 1;
          show-process-indicators = true;
          tilesize = 40;
          persistent-apps = config.dendritic.dock.apps;
        };

        startup.chime = false;
        defaults = {
          LaunchServices.LSQuarantine = false;

          smb = {
            NetBIOSName = config.networking.hostName;
            ServerDescription = null;
          };

          CustomUserPreferences = {
            "NSGlobalDomain".ApplePersistence = false;
            "com.apple.sidebarlists".systemitems.ShowAirDrop = true;
          };
        };
      };

      networking.applicationFirewall = {
        allowSignedApp = true;
        allowSigned = true;
      };
    };
  };
}
