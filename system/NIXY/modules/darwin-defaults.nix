{ config, ... }:

# SYSTEM DEFAULTS!!!! MACOS defaults config.
{
  system = {
    activationScripts.postUserActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    startup.chime = false; # MUTE STARTUP CHIME!
    defaults = {
      finder = {
        CreateDesktop = false; # REQUIRED true to fix https://github.com/koekeishiya/yabai/issues/863 and https://github.com/koekeishiya/yabai/issues/2313#issuecomment-2225438696
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowPathbar = false;
        ShowStatusBar = false;
        _FXShowPosixPathInTitle = true;
      };
      loginwindow = {
        DisableConsoleAccess = true;
        GuestEnabled = false;
        LoginwindowText = "${config.networking.hostName}";
        PowerOffDisabledWhileLoggedIn = false;
        RestartDisabled = false;
        RestartDisabledWhileLoggedIn = false;
        SHOWFULLNAME = false;
        ShutDownDisabled = false;
        ShutDownDisabledWhileLoggedIn = false;
        SleepDisabled = false;
        autoLoginUser = null;
      };
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark"; # or null; for normal. ##FIXME: TRIGGER WITH COLORSCHEME!
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
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      alf = {
        allowdownloadsignedenabled = 1;
        allowsignedenabled = 1;
      };
      spaces.spans-displays = false; # Required false for yabai!
      dock = {
        autohide = true;
        autohide-delay = 1000.0;
        autohide-time-modifier = 0.0; # speed of hide/show
        expose-animation-duration = 0.1;
        orientation = "bottom";
        show-recents = false;
        showhidden = true;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        show-process-indicators = false;
        tilesize = 40;
      };
      menuExtraClock = {
        IsAnalog = true;
        ShowSeconds = true;
      };
      trackpad = {
        ActuationStrength = 0;
        Clicking = false;
        Dragging = true;
        FirstClickThreshold = 1;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };
      universalaccess = {
        mouseDriverCursorSize = 1.2;
        reduceMotion = true;
        reduceTransparency = true;
      };
      ".GlobalPreferences"."com.apple.mouse.scaling" = 8.0;
      ActivityMonitor.IconType = null;
      CustomSystemPreferences = {
        NSGlobalDomain = {
          TISRomanSwitchState = 1;
          NSAutomaticWindowAnimationsEnabled = false;
          NSScrollAnimationEnabled = false;
          NSWindowResizeTime = 0.001;
          QLPanelAnimationDuration = 0;
          NSScrollViewRubberbanding = false;
          NSDocumentRevisionsWindowTransformAnimation = false;
          NSToolbarFullScreenAnimationDuration = 0;
          NSBrowserColumnAnimationSpeedMultiplier = 0;
        };
        "com.apple.finder".DisableAllAnimations = true;
        "com.apple.Mail" = {
          DisableSendAnimations = true;
          DisableReplyAnimations = true;
        };
        "com.apple.Safari"."com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
        "/Library/Preferences/com.apple.security.libraryvalidation".DisableLibraryValidation = true;
        "/Library/Preferences/com.apple.Accessibility" = {
          AccessibilityEnabled = 1;
          ApplicationAccessibilityEnabled = 1;
          KeyRepeatEnabled = 1;
          KeyRepeatDelay = "0.5";
          KeyRepeatInterval = "0.083333333";
          DarkenSystemColors = 1;
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
          TrackpadFiveFingerPinchGesture = 2;
          TrackpadFourFingerHorizSwipeGesture = 2;
          TrackpadFourFingerPinchGesture = 2;
          TrackpadFourFingerVertSwipeGesture = 2;
          TrackpadHandResting = 1;
          TrackpadHorizScroll = 1;
          TrackpadMomentumScroll = 1;
          TrackpadPinch = 1;
          TrackpadRightClick = 1;
          TrackpadRotate = 1;
          TrackpadScroll = 1;
          TrackpadThreeFingerDrag = 0;
          TrackpadThreeFingerHorizSwipeGesture = 2;
          TrackpadThreeFingerTapGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 2;
          TrackpadTwoFingerDoubleTapGesture = 1;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
          USBMouseStopsTrackpad = 0;
          UserPreferences = 1;
        };
        ".GlobalPreferences" = {
          AppleAccentColor = 4;
          AppleAntiAliasingThreshold = 4;
          AppleAquaColorVariant = 1;
          AppleEnableMouseSwipeNavigateWithScrolls = 0;
          AppleEnableSwipeNavigateWithScrolls = 0;
          AppleFontSmoothing = 0;
          AppleHighlightColor = "0.698039 0.843137 1.000000 Blue";
          AppleInterfaceStyle = "Dark";
          AppleLanguages = [ "en-US" ];
          AppleLocale = "en_US";
          AppleMenuBarVisibleInFullscreen = 0;
          AppleMiniaturizeOnDoubleClick = 0;
          AppleShowAllFiles = 1;
          NSAutomaticCapitalizationEnabled = 0;
          NSAutomaticDashSubstitutionEnabled = 0;
          NSAutomaticPeriodSubstitutionEnabled = 0;
          NSAutomaticQuoteSubstitutionEnabled = 0;
          NSAutomaticSpellingCorrectionEnabled = 0;
          NSAutomaticWindowAnimationsEnabled = 0;
          NSScrollAnimationEnabled = 0;
          NSUseAnimatedFocusRing = 0;
          NSWindowResizeTime = "0.001";
          NSWindowSupportsAutomaticInlineTitle = 0;
          TISRomanSwitchState = 1;
          _HIHideMenuBar = 1;
          "com.apple.mouse.scaling" = 8;
          "com.apple.scrollwheel.scaling" = "-1";
          "com.apple.sound.beep.feedback" = 1;
          "com.apple.sound.beep.flash" = 0;
          "com.apple.sound.beep.volume" = 0;
          "com.apple.springing.delay" = "0.5";
          "com.apple.springing.enabled" = 1;
          "com.apple.trackpad.forceClick" = 1;
        };
      };
      CustomUserPreferences = {
        NSGlobalDomain.TISRomanSwitchState = 1;
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
          AutoStartSettingIsHidden = 2; # startup mode: hidden = 1, on = 0, disabled = 2
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
          DisableMouseAccel = 0;
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
          globalKey = { length = 142; bytes = "0x7b22636170734c6f636b223a66616c7364223a747275657d"; };
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
          "audioDevice.selected" = "BGMDevice"; # select BGM for Cava to work.
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
      LaunchServices.LSQuarantine = false;
      magicmouse.MouseButtonMode = "TwoButton";
      screencapture = {
        disable-shadow = true;
        location = "~/Desktop/Screenshots";
        type = "png";
      };
      screensaver.askForPassword = true;
      smb = {
        NetBIOSName = "${config.networking.hostName}";
        ServerDescription = null;
      };
    };
  };
}
