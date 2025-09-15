# NIXI plist-manager Configuration
# Intel macOS optimized system settings
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable plist-manager with NIXI preset
  nix-plist-manager = {
    enable = true;
    users = ["alex"];

    # System settings
    systemSettings = {
      # General settings
      general = {
        softwareUpdate = {
          automaticallyDownloadNewUpdatesWhenAvailable = true;
          automaticallyInstallMacOSUpdates = false;
        };
      };

      # Appearance settings
      appearance = {
        appearance = "Auto";
        accentColor = "Green";
      };

      # Control Center (complete configuration required by nix-plist-manager)
      controlCenter = {
        wifi = true;
        bluetooth = true;
        airdrop = true;
        stageManager = false;
        focusModes = "active";
        screenMirroring = "active";
        display = "active";
        sound = "always";
        nowPlaying = "active";

        accessibilityShortcuts = {
          showInMenuBar = false;
          showInControlCenter = true;
        };

        musicRecognition = {
          showInMenuBar = false;
          showInControlCenter = true;
        };

        hearing = {
          showInMenuBar = false;
          showInControlCenter = true;
        };

        fastUserSwitching = {
          showInMenuBar = false;
          showInControlCenter = false;
        };

        keyboardBrightness = {
          showInMenuBar = false;
          showInControlCenter = true;
        };

        battery = {
          showInMenuBar = true;
          showInControlCenter = true;
        };

        batteryShowPercentage = true;

        menuBarOnly = {
          spotlight = true;
          siri = false;
        };

        automaticallyHideAndShowTheMenuBar = "Never";
      };

      # Desktop and Dock settings
      desktopAndDock = {
        dock = {
          size = 48;
          positionOnScreen = "Bottom";
        };
      };
    };

    # Application settings (only Finder is supported)
    applications.finder.settings.advanced = {
      showAllFilenameExtensions = true;
      removeItemsFromTheTrashAfter30Days = true;
    };
  };
}
