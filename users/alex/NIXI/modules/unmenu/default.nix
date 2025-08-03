{
  config,
  lib,
  pkgs,
  std,
  ...
}: let
  cfg = config.programs.unmenu;
  unmenu = pkgs.stdenv.mkDerivation rec {
    pname = "unmenu";
    version = "0.2";

    src = pkgs.fetchurl {
      url = "https://github.com/unmanbearpig/unmenu/releases/download/v${version}/unmenu.app.zip";
      sha256 = "sha256-c4fe1g9XBTXR6KtJn5njy28q4SyUM/r5hGV3Nd1ztdY=";
    };

    nativeBuildInputs = [pkgs.unzip];

    installPhase = ''
      mkdir -p $out/Applications
      unzip -q $src -d $out/Applications
      mkdir -p $out/bin
      ln -s $out/Applications/unmenu.app/Contents/MacOS/unmenu $out/bin/unmenu
    '';

    meta = with lib; {
      description = "A macOS app for quick application launching, forked from dmenu-mac";
      longDescription = ''
        unmenu is a fork of dmenu-mac, enhancing its functionality and addressing certain issues.
        It uses the Accessibility API for handling hotkeys and implements a superior fuzzy matching algorithm.
        Users can customize search directories, filter out applications, and integrate scripts and aliases.
      '';
      homepage = "https://github.com/unmanbearpig/unmenu";
      platforms = platforms.darwin;
      license = licenses.mit;
      maintainers = with maintainers; [unmanbearpig];
    };
  };
in {
  options.programs.unmenu = {
    enable = lib.mkEnableOption "unmenu";

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          hotkey = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {
              qwerty_hotkey = "ctrl-cmd-space";
            };
            description = "Hotkey settings for unmenu";
          };

          find_apps = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to find applications";
          };

          find_executables = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to find executables";
          };

          dirs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "/System/Applications/"
              "/Applications/"
              "/System/Applications/Utilities/"
              "/System/Library/CoreServices/"
            ];
            description = "Directories to search for applications";
          };

          ignore_names = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "unmenu.app"
              ".Karabiner-VirtualHIDDevice-Manager.app"
              "Install Command Line Developer Tools.app"
              "Install in Progress.app"
              "Migration Assistant.app"
              "TextInputMenuAgent.app"
              "TextInputSwitcher.app"
              "AOSUIPrefPaneLauncher.app"
              "Automator Application Stub.app"
              "NetAuthAgent.app"
              "Captive Network Assistant.app"
              "screencaptureui.app"
              "ScreenSaverEngine.app"
              "SystemUIServer.app"
              "UIKitSystem.app"
              "NowPlayingTouchUI.app"
              "WindowManager.app"
              "APFSUserAgent"
              "AVB Audio Configuration.app"
              "AddPrinter.app"
              "AddressBookUrlForwarder.app"
              "AirPlayUIAgent.app"
              "AirPort Base Station Agent.app"
              "AppleScript Utility.app"
              "Automator Application Stub.app"
              "Automator Installer.app"
              "BluetoothSetupAssistant.app"
              "BluetoothUIServer.app"
              "BluetoothUIService.app"
              "CSUserAgent"
              "CalendarFileHandler.app"
              "Captive Network Assistant.app"
              "Certificate Assistant.app"
              "CloudSettingsSyncAgent"
              "ControlCenter.app"
              "ControlStrip.app"
              "CoreLocationAgent.app"
              "CoreServicesUIAgent.app"
              "Coverage Details.app"
              "CrashReporterSupportHelper"
              "DMProxy"
              "Database Events.app"
              "DefaultBackground.jpg"
              "DefaultDesktop.heic"
              "Diagnostics Reporter.app"
              "DiscHelper.app"
              "DiskImageMounter.app"
              "Dock.app"
              "Dwell Control.app"
              "Erase Assistant.app"
              "EscrowSecurityAlert.app"
              "ExpansionSlotNotification"
              "FolderActionsDispatcher.app"
              "HelpViewer.app"
              "IOUIAgent.app"
              "Image Events.app"
              "Install Command Line Developer Tools.app"
              "Install in Progress.app"
              "Installer Progress.app"
              "Installer.app"
              "JavaLauncher.app"
              "KeyboardAccessAgent.app"
              "KeyboardSetupAssistant.app"
              "Keychain Circle Notification.app"
              "Language Chooser.app"
              "MTLReplayer.app"
              "ManagedClient.app"
              "MapsSuggestionsTransportModePrediction.mlmodelc"
              "MemorySlotNotification"
              "Menu Extras"
              "NetAuthAgent.app"
              "NowPlayingTouchUI.app"
              "OBEXAgent.app"
              "ODSAgent.app"
              "OSDUIHelper.app"
              "PIPAgent.app"
              "PodcastsAuthAgent.app"
              "PowerChime.app"
              "Pro Display Calibrator.app"
              "Problem Reporter.app"
              "ProfileHelper.app"
              "RapportUIAgent.app"
              "RegisterPluginIMApp.app"
              "RemoteManagement"
              "RemotePairTool"
              "ReportCrash"
              "Resources"
              "RestoreVersion.plist"
              "Rosetta 2 Updater.app"
              "ScopedBookmarkAgent"
              "ScreenSaverEngine.app"
              "Script Menu.app"
              "ScriptMonitor.app"
              "SecurityAgentPlugins"
              "ServicesUIAgent"
              "Setup Assistant.app"
              "SetupAssistantPlugins"
              "ShortcutDroplet.app"
              "Shortcuts Events.app"
              "SpacesTouchBarAgent.app"
              "StageManagerEducation.app"
              "SubmitDiagInfo"
              "SystemFolderLocalizations"
              "SystemUIServer.app"
              "SystemVersion.plist"
              "SystemVersionCompat.plist"
              "TextInputMenuAgent.app"
              "TextInputSwitcher.app"
              "ThermalTrap.app"
              "Tips.app"
              "UAUPlugins"
              "UIKitSystem.app"
              "UniversalAccessControl.app"
              "UniversalControl.app"
              "UnmountAssistantAgent.app"
              "UserAccountUpdater"
              "UserNotificationCenter.app"
              "UserPictureSyncAgent"
              "VoiceOver.app"
              "WatchFaceAlert.app"
              "WiFiAgent.app"
              "WidgetKit Simulator.app"
              "WindowManager.app"
              "Xcode Previews.app"
              "appleeventsd"
              "boot.efi"
              "cacheTimeZones"
              "cloudpaird"
              "com.apple.NSServicesRestrictions.plist"
              "coreservicesd"
              "destinationd"
              "diagnostics_agent"
              "iCloud+.app"
              "iCloud.app"
              "iOSSystemVersion.plist"
              "iTunesStoreURLPatterns.plist"
              "iconservicesagent"
              "iconservicesd"
              "ionodecache"
              "launchservicesd"
              "lockoutagent"
              "logind"
              "loginwindow.app"
              "mapspushd"
              "navd"
              "osanalyticshelper"
              "pbs"
              "rc.trampoline"
              "rcd.app"
              "screencaptureui.app"
              "sessionlogoutd"
              "sharedfilelistd"
              "talagent"
              "uncd"
              "NotificationCenter.app"
            ];
            description = "List of application names to ignore";
          };

          ignore_patterns = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "^Install.*"
              ".*Installer\\.app$"
              "\\.bundle$"
            ];
            description = "List of patterns to ignore when searching for applications";
          };
        };
      };
      default = {};
      description = "Unmenu settings";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [unmenu];
    home.file.".config/unmenu/config.toml" = {
      force = true;
      text = std.serde.toTOML cfg.settings;
    };
  };
}
