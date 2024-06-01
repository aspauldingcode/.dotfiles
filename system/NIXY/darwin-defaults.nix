{ config, ... }:

##SYSTEM DEFAULTS!!!! MACOS defaults config.
{
  system = {
    startup.chime = false; # MUTE STARTUP CHIME!
    defaults = {
      finder = {
        CreateDesktop = false; # REQUIRED to fix https://github.com/koekeishiya/yabai/issues/863
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
        NSWindowResizeTime = 0.0;
        NSUseAnimatedFocusRing = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        _HIHideMenuBar = true; # Auto-hide window bar
        AppleEnableMouseSwipeNavigateWithScrolls = false;
        AppleEnableSwipeNavigateWithScrolls = false;
        "com.apple.sound.beep.volume" = 0.0; # mute beep/alert volume
        "com.apple.sound.beep.feedback" = 1; # enable volume changed feedback.
        NSWindowShouldDragOnGesture = null;
        PMPrintingExpandedStateForPrint = null;
        PMPrintingExpandedStateForPrint2 = null;
        "com.apple.springing.delay" = null;
        "com.apple.springing.enabled" = null;
        "com.apple.swipescrolldirection" = null;
        "com.apple.trackpad.enableSecondaryClick" = null;
        # "com.apple.trackpad.forceClick" = null;
        "com.apple.trackpad.scaling" = null;
        "com.apple.trackpad.trackpadCornerClickBehavior" = null;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false; # always up to date?
      alf.allowdownloadsignedenabled = null;
      alf.allowsignedenabled = null;
      spaces = {
        spans-displays = false; # Required false for yabai!
      };
      dock = {
        autohide = false;
        autohide-delay = 1000.0; # defaults write com.apple.dock autohide-delay -float 1000; killall Dock
        autohide-time-modifier = null; # 0.001 or null?
        dashboard-in-overlay = true;
        expose-animation-duration = 1.0e-3; # or null?
        expose-group-by-app = null;
        launchanim = false;
        orientation = "bottom";
        show-recents = false;
        showhidden = true;
        wvous-bl-corner = 1; # 1 for disable
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        appswitcher-all-displays = null;
        largesize = null;
        magnification = null;
        mineffect = null;
        minimize-to-application = null;
        show-process-indicators = null;
        static-only = null;
        tilesize = 40;
      };
      menuExtraClock = {
        IsAnalog = true;
        Show24Hour = null;
        ShowAMPM = null;
        ShowDate = null;
        ShowDayOfMonth = null;
        ShowDayOfWeek = null;
        ShowSeconds = true;
      };
      trackpad = {
        ActuationStrength = 0; # 0 for silent clicking, 1 to disable
        Clicking = false; # tap to click
        Dragging = true; # tap to drag
        FirstClickThreshold = 1;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };
      universalaccess = {
        mouseDriverCursorSize = 1.2; # Cursor size
        reduceMotion = true;
        reduceTransparency = true;
      };
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 8.0; # Set to -1.0 to disable mouse acceleration.
        "com.apple.sound.beep.sound" = null;
      };
      ActivityMonitor.IconType = null;
      CustomSystemPreferences = {
        # for the whole system
        NSGlobalDomain = {
          TISRomanSwitchState = 1;
        };
        "com.apple.Safari" = {
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
        };
        "/Library/Preferences/com.apple.security.libraryvalidation" = {
          DisableLibraryValidation = true; # required for macEnhance!
        };
        "/Library/Preferences/com.apple.Accessibility" = {
          AccessibilityEnabled = 1;
          ApplicationAccessibilityEnabled = 1;
          KeyRepeatEnabled = 1;
          KeyRepeatDelay = "0.5";
          KeyRepeatInterval = "0.083333333";
          DarkenSystemColors = 1;
        };
      };
      CustomUserPreferences = {
        # per user
        NSGlobalDomain = {
          TISRomanSwitchState = 1;
        };
        #"com.apple.Safari" = {
        #  "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
        #};
        "....X11" = {
          enable_fake_buttons = 1;
          fullscreen_hotkeys = 1; # 1 is true, 0 is false!
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
          sync_clipboard_to_pasteboard = true; # becomes your x11 clipboard manager, disables other x11 clipboard managers
          sync_primary_on_select = true; # is this needed for zellij???
          enable_test_extensions = false;
          scroll_in_device_direction = false; # true overrides macos setting in Mouse/Trackpad
        };
        "org.xquartz.X11" = {
          "NSWindow Frame x11_apps" = "243 364 454 299 0 0 1440 900 ";
          "NSWindow Frame x11_prefs" = "313 422 484 336 0 0 1440 900 ";
          # SUHasLaunchedBefore = 1; #NO!L:
          # SULastCheckTime = "2024-03-13 16:40:49 +0000"; #NO!
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
          "no_auth" = 0; # required
          "nolisten_tcp" = 0; # allow docker connections
          "option_sends_alt" = true; # MUST BE TRUE for using ALT as Mod1 in i3! (NOTE: disable skhd if using xquartz!)
          "startx_script" = "/opt/X11/bin/startx -- /opt/X11/bin/Xquartz";
        };
        "com.dwarvesv.minimalbar" = {
          "NSStatusItem Preferred Position hiddenbar_expandcollapse" = 78;
          "NSStatusItem Preferred Position hiddenbar_separate" = 110;
          "NSStatusItem Preferred Position hiddenbar_terminate" = 146;
          alwaysHiddenSectionEnabled = 1;
          areSeparatorsHidden = 0;
          globalKey = { length = 142; bytes = "0x7b22636170734c6f636b223a66616c7364223a747275657d"; };
          isAutoHide = 1;
          isAutoStart = 1;
          isShowPreferences = 0;
          useFullStatusBarOnExpandEnabled = 0;
        };
      #   vscode = {
      #   settings = {
      #     "window.systemColorTheme" = "auto";
      #   };
      # };
      };
      LaunchServices.LSQuarantine = false;
      magicmouse.MouseButtonMode = "TwoButton"; # allow left and right click when using magic mouse.
      screencapture = {
        disable-shadow = true;
        # location = "${config.home.homeDirectory}/Desktop"; # save captures to the Desktop (backed by icloud!)
        type = "png";
      };
      screensaver = {
        askForPassword = true;
        # askForPasswordDelay = 7320; #same as swaylock on sway.nix NIXSTATION64 timeout config.
      };
      smb = {
        NetBIOSName = "${config.networking.hostName}";
        ServerDescription = null;
      };
    };
  };
}
