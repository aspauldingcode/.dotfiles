{
  flake.modules.darwin.dendritic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.dendritic.dock.apps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Ordered list of .app paths to pin in the Dock.";
      };

      # Each app module registers its own dock entry via `lib.mkOrder`.
      # Lower priority → further left in the dock.
      #
      #     0  system launchers (`dock.nix`)
      #   100  Safari (`apps/safari.nix`) + Firefox (`apps/firefox.nix`)
      #   110  Brave (`apps/brave.nix`)
      #   120  Spotify (`apps/spotify.nix`)
      #   130  Vesktop (`apps/vesktop.nix`)
      #   140  Ghostty (`apps/ghostty.nix`)
      #   145  QtPass (`apps/pass.nix`)
      #   150  JetBrains IDEs (`apps/jetbrains.nix`)
      #   160  Cursor (`apps/cursor.nix`)
      #   170  Antigravity (`apps/antigravity.nix`)

      config = {
        # System apps appear first in the dock.
        dendritic.dock.apps = lib.mkOrder 0 [
          "/System/Applications/Apps.app"
          "/System/Applications/System Settings.app"
        ];

        system = {
          defaults.dock = {
            autohide = false;
            expose-animation-duration = 0.1;
            minimize-to-application = true;
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
            finder.CreateDesktop = false;

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
