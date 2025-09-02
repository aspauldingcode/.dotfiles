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
    users = [ "alex" ];
    
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
      
      # Desktop and Dock settings
      desktopAndDock = {
        dock = {
          size = 48;
          positionOnScreen = "bottom";
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