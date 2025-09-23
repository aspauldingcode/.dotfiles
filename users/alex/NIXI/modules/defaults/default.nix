{
  config,
  pkgs,
  nix-colors,
  ...
}:
{
  targets.darwin.defaults = {
    "NSGlobalDomain" = {
      NSColorSimulateHardwareAccent = true;
      NSColorSimulatedHardwareEnclosureNumber = 4;
      AppleHighlightColor =
        let
          hexColor = "${config.colorScheme.palette.base0D}";
          hexColorConverted = builtins.toString (
            (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColor)) ++ [ "Other" ]
          );
        in
        hexColorConverted;
      TISRomanSwitchState = 1;
      AppleInterfaceStyle = if config.colorScheme.variant == "dark" then "Dark" else "Light";
      AppleShowAllFiles = true;
      NSScrollAnimationEnabled = false;
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      NSUseAnimatedFocusRing = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      _HIHideMenuBar = true;
      AppleEnableMouseSwipeNavigateWithScrolls = false;
      AppleEnableSwipeNavigateWithScrolls = false;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 1;
      AppleFontSmoothing = 0;
    };

    "com.apple.finder" = {
      CreateDesktop = false;
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = false;
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
    };

    "com.apple.dock" = {
      autohide = true;
      # autohide-delay = 1000.0;
      # autohide-time-modifier = 0.0;
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
      persistent-apps = [
        "/System/Applications/Launchpad.app"
        # "/Applications/Nix\ Apps/Spotify.app"
        # "${config.programs.spicetify.spicedSpotify}/Applications/Spotify.app"
        "${pkgs.obsidian}/Applications/Obsidian.app"
      ]
      ++ (
        if pkgs.stdenv.isDarwin then
          [ ]
        else
          [
            "${pkgs.firefox-bin}/Applications/Firefox.app"
          ]
      )
      ++ [
        "${pkgs.brave}/Applications/Brave Browser.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Facetime.app"
        "/Applications/Windows App.app"
        "${pkgs.alacritty}/Applications/Alacritty.app"
      ];
    };

    "com.apple.menuextra.clock" = {
      IsAnalog = true;
      ShowSeconds = true;
    };

    "com.apple.trackpad" = {
      ActuationStrength = 1;
      Clicking = false;
      Dragging = true;
      FirstClickThreshold = 1;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    "com.apple.universalaccess" = {
      mouseDriverCursorSize = 1.2;
      reduceMotion = true;
      reduceTransparency = true;
    };

    ".GlobalPreferences"."com.apple.mouse.scaling" = 8.0;

    "com.apple.WindowManager" = {
      EnableStandardClickToShowDesktop = false;
    };

    "com.apple.spaces" = {
      "spans-displays" = false;
    };

    "com.apple.hitoolbox" = {
      AppleFnUsageType = "Do Nothing";
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "com.apple.screencapture" = {
      disable-shadow = true;
      location = "~/Desktop/Screenshots";
      type = "png";
    };

    "com.apple.screensaver" = {
      askForPassword = true;
    };

    "com.apple.alf" = {
      allowdownloadsignedenabled = 1;
      allowsignedenabled = 1;
    };

    "com.apple.LaunchServices" = {
      LSQuarantine = false;
    };

    "com.apple.magicmouse" = {
      MouseButtonMode = "TwoButton";
    };

    "....X11" = {
      enable_fake_buttons = 1;
      fullscreen_hotkeys = 1;
      fullscreen_menu = true;
      no_quit_alert = true;
      no_auth = true;
      nolisten_tcp = false;
      enable_system_beep = false;
      enable_key_equivalents = false;
      sync_keymap = true;
      sync_pasteboard = true;
      sync_pasteboard_to_clipboard = true;
      sync_pasteboard_to_primary = true;
      sync_clipboard_to_pasteboard = true;
      sync_primary_on_select = true;
      enable_test_extensions = false;
      scroll_in_device_direction = false;
    };

    "com.spotify.client" = {
      AutoStartSettingIsHidden = 2;
      NSFullScreenMenuItemEverywhere = 0;
      NSIsFullScreen = 0;
      "NSWindow Frame com.spotify.client.mainwindow" = "371 -178 800 600 0 0 1440 900 ";
      "run_mode" = "clean_quit";
    };

    "com.macenhance.MacForge" = {
      MF_AMFIShowWarning = 1;
      MSAppCenter310AnalyticsUserDefaultsMigratedKey = 1;
      MSAppCenter310AppCenterUserDefaultsMigratedKey = 1;
      MSAppCenter310CrashesUserDefaultsMigratedKey = 1;
      SUAutomaticallyUpdate = 1;
      SUEnableAutomaticChecks = 0;
      SUSendProfileInfo = 0;
      SUSkippedVersion = 5977;
      SUUpdateRelaunchingMarker = 0;
      moveToApplicationsFolderAlertSuppress = 1;
      updateCount = "";
    };

    "com.macenhance.MacForgeHelper" = {
      "NSStatusItem Preferred Position Item-0" = 359;
      SIMBLApplicationIdentifierBlacklist = [
        "org.w0lf.mySIMBL"
        "org.w0lf.cDock-GUI"
        "org.w0lf.cDockHelper"
        "com.macenhance.MacForge"
        "com.macenhance.MacForgeHelper"
        "com.macenhance.purchaseValidationApp"
      ];
    };

    "com.theron.UnnaturalScrollWheels" = {
      AlternateDetectionMethod = 0;
      DisableMouseAccel = 1;
      DisableScrollAccel = 1;
      FirstLaunch = 0;
      InvertHorizonalScroll = 0;
      InvertHorizontalScroll = 0;
      InvertVerticalScroll = 1;
      LaunchAtLogin = 1;
      "NSStatusItem Preferred Position Item-0" = 255;
      OriginalAccel = 524288;
      ScrollLines = 3;
      ShowMenuBarIcon = 1;
    };

    "com.apple.AppleMultitouchTrackpad" = {
      ActuateDetents = 1;
      ActuationStrength = 0;
      Clicking = 0;
      DragLock = 0;
      Dragging = 1;
      FirstClickThreshold = 1;
      ForceSuppressed = 1;
      SecondClickThreshold = 1;
      TrackpadCornerSecondaryClick = 0;
      TrackpadFiveFingerPinchGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 0;
      TrackpadFourFingerPinchGesture = 0;
      TrackpadFourFingerVertSwipeGesture = 0;
      TrackpadHandResting = 1;
      TrackpadHorizScroll = 1;
      TrackpadMomentumScroll = 1;
      TrackpadPinch = 1;
      TrackpadRightClick = 1;
      TrackpadRotate = 1;
      TrackpadScroll = 1;
      TrackpadThreeFingerDrag = 0;
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 0;
      USBMouseStopsTrackpad = 0;
      UserPreferences = 1;
    };

    "dev.kdrag0n.MacVirt" = {
      SUHasLaunchedBefore = 1;
      SUSendProfileInfo = 1;
      admin_dismissCount = 0;
      docker_migrationDismissed = 1;
      drm_lastState = ''{"entitlementTier":0,"entitlementType":0}'';
      global_showMenubarExtra = 1;
      onboardingCompleted = 1;
      selectedTab = "machines";
      tips_containerDomainsShow = 0;
      tips_containerFilesShow = 0;
      tips_imageMountsShow = 0;
      tips_menubarBgShown2 = 1;
    };

    "org.xquartz.X11" = {
      "app_to_run" = "/opt/X11/bin/xterm";
      "apps_menu" = [
        "Terminal"
        "xterm"
        ""
        "dmenu"
        "dmenu_run"
        ""
      ];
      "cache_fonts" = 1;
      depth = 24;
      "done_xinit_check" = 1;
      "enable_iglx" = 1;
      "login_shell" = "/bin/sh";
      "no_auth" = 0;
      "nolisten_tcp" = 0;
      "option_sends_alt" = true;
      "startx_script" = "/opt/X11/bin/startx -- /opt/X11/bin/Xquartz";
      dpi = 227;
    };

    "com.doomlaser.cursorcerer" = {
      autoShow = 1;
      idleHide = "8.0";
      toggleCursorHotKey = {
        keyCode = 40;
        modifiers = 6144;
      };
    };

    "com.dwarvesv.minimalbar" = {
      "NSStatusItem Preferred Position hiddenbar_expandcollapse" = 78;
      "NSStatusItem Preferred Position hiddenbar_separate" = 110;
      "NSStatusItem Preferred Position hiddenbar_terminate" = 146;
      alwaysHiddenSectionEnabled = 1;
      areSeparatorsHidden = 0;
      globalKey = {
        length = 144;
      };
      isAutoHide = 0;
      isAutoStart = 0;
      isShowPreferences = 0;
      numberOfSecondForAutoHide = 10;
      useFullStatusBarOnExpandEnabled = 0;
    };

    "com.bearisdriving.BGM.App" = {
      SelectedMusicPlayerID = "EC2A907F-8515-4687-9570-1BF63176E6D8";
      StatusBarIcon = 0;
    };

    "com.apple.audio.AudioMIDISetup" = {
      "audioDevice.selected" = "BGMDevice";
    };

    "~/Library/Preferences/ByHost/com.apple.controlcenter" = {
      Bluetooth = 2;
      UserSwitcher = 2;
      WiFi = 2;
      AirDrop = 18;
      VoiceControl = 8;
      FocusModes = 2;
      ScreenMirroring = 18;
      Sound = 18;
      StageManager = 18;
      Display = 18;
      NowPlaying = 18;
    };
  };
}
