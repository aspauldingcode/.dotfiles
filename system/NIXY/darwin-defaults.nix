{ config, ... }:

##SYSTEM DEFAULTS!!!! MACOS defaults config.
{
  system = {
    activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

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
        NSWindowResizeTime = 0.001; # Increase Window Resize Speed for Cocoa Applications
        NSUseAnimatedFocusRing = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false; # Disable Auto-correct System-wide
        NSAutomaticDashSubstitutionEnabled = false; # Disable Smart Dashes System-wide
        NSAutomaticPeriodSubstitutionEnabled = false; # Disable Automatic Period Substitution System-wide
        NSAutomaticQuoteSubstitutionEnabled = false; # Disable Smart Quotes System-wide
        _HIHideMenuBar = true; # Auto-hide window bar
        AppleEnableMouseSwipeNavigateWithScrolls = false;
        AppleEnableSwipeNavigateWithScrolls = false; # Disable Smooth Scrolling
        "com.apple.sound.beep.volume" = 0.0; # mute beep/alert volume
        "com.apple.sound.beep.feedback" = 1; # enable volume changed feedback.
        NSWindowShouldDragOnGesture = null;
        PMPrintingExpandedStateForPrint = null;
        PMPrintingExpandedStateForPrint2 = null;
        "com.apple.springing.delay" = null;
        "com.apple.springing.enabled" = null;
        "com.apple.swipescrolldirection" = null;
        "com.apple.trackpad.enableSecondaryClick" = null;
        "com.apple.trackpad.scaling" = null;
        "com.apple.trackpad.trackpadCornerClickBehavior" = null;
        AppleFontSmoothing = 0; # Add this line
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false; # always up to date?
      alf.allowdownloadsignedenabled = 1;
      alf.allowsignedenabled = 1;
      spaces = {
        spans-displays = false; # Required false for yabai!
      };
      dock = {
        autohide = false;
        autohide-delay = 0.0; # Remove Delay When Hiding the Dock
        autohide-time-modifier = null; # 0.001 or null?
        dashboard-in-overlay = false; # Disable the Dashboard
        expose-animation-duration = 0.1; # Speed Up Mission Control Animations
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
        show-process-indicators = false; # Disable Spring Loading for All Dock Items
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
        # CGDisableCursorLocationMagnification = true; # Disables shake to find cursor
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
          # General UI/UX Animation and Behavior Modifications
          # Disable various system animations
          # Run these commands manually in the terminal to set preferences
          "NSAutomaticWindowAnimationsEnabled" = false; # Disable automatic window animations
          "NSScrollAnimationEnabled" = false; # Disable scroll animations
          "NSWindowResizeTime" = 0.001; # Speed up window resize time
          "QLPanelAnimationDuration" = 0; # Disable Quick Look panel animations
          "NSScrollViewRubberbanding" = false; # Disable rubberband scrolling
          "NSDocumentRevisionsWindowTransformAnimation" = false; # Disable document revisions window transform animations
          "NSToolbarFullScreenAnimationDuration" = 0; # Disable full screen toolbar animations
          "NSBrowserColumnAnimationSpeedMultiplier" = 0; # Disable browser column animation speed
        };
        "com.apple.dock" = {
          # Dock-specific animations and delays
          "autohide-time-modifier" = 0; # Remove animation time for auto-hiding the dock
          "autohide-delay" = 0; # Remove delay for auto-hiding the dock
          "expose-animation-duration" = 0; # Speed up Mission Control animations
          "springboard-show-duration" = 0; # Disable Launchpad show animation
          "springboard-hide-duration" = 0; # Disable Launchpad hide animation
          "springboard-page-duration" = 0; # Disable Launchpad page transition animations
        };
        "com.apple.finder" = {
          "DisableAllAnimations" = true; # Disable all Finder animations
        };
        "com.apple.Mail" = {
          "DisableSendAnimations" = true; # Disable send animations in Mail app
          "DisableReplyAnimations" = true; # Disable reply animations in Mail app
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
        "/Library/Preferences/com.apple.ARDAgent" = {
          ARDAdmin_AppStoreURL = "macappstore://itunes.apple.com/us/app/apple-remote-desktop/id409907375";
          Version = "3.6";
        };
        "/Library/Preferences/com.apple.AppleFileServer" = {
          kerberosPrincipal = "afpserver/LKDC:SHA1.9D418C990AE27D72ECF3F1462D9014B820FED218@LKDC:SHA1.9D418C990AE27D72ECF3F1462D9014B820FED218";
        };
        "/Library/Preferences/com.apple.AssetCache" = {
          Activated = 0;
          CacheLimit = 0;
          DataPath = "/Library/Application Support/Apple/AssetCache/Data";
          ListenWithPeersAndParents = 1;
          LocalSubnetsOnly = 1;
          PeerLocalSubnetsOnly = 1;
          Port = 0;
          ReservedVolumeSpace = 2000000000;
          ServerGUID = "648D7F22-D92B-48F9-A66F-031D87F18225";
          Version = 1;
        };
        "/Library/Preferences/com.apple.BezelServices" = {
          BatteryHistory = {};
          afActionHistory = {};
        };
        "/Library/Preferences/com.apple.ByteRangeLocking" = {
          DB_HASH_TABLE_MAX = 4096;
          DB_INIT_SIZE = 2097152;
          DB_Location = "/var/db/BRLM.db";
          DB_PROC_TABLE_MAX = 1000;
        };
        "/Library/Preferences/com.apple.bluetooth" = {
            BluetoothAutoSeekKeyboard = 1;
            BluetoothAutoSeekPointingDevice = 1;
            PersistentPorts =     {
                "C0:86:B3:6F:97:7A" =         {
                    BSDName = "OpenRunProbyShokz";
                    BTAddress = { length = 6; bytes = "0xc086b36f977a"; };
                    RFCOMMChannel = 1;
                };
            };
            SpatialSoundProfileAllowed = 1;
            moveAllAppleHIDsTo15 = 0;
        };
        "com.apple.RemoteDesktop" = {
          DOCAllowRemoteConnections = 0;
          RSAKeySize = 2048;
          Text1 = "";
          Text2 = "";
          Text3 = "";
          Text4 = "";
        };
        "com.apple.RemoteManagement" = {
          AllowSRPForNetworkNodes = 0;
          DisableKerberos = 0;
          VNCLegacyConnectionsEnabled = 1;
          allowInsecureDH = 1;
        };

        com.apple.TimeMachine = {
              PreferencesVersion = 5;
            };

            com.apple.airport.opproam = {
              deltaRSSI = 10;
              disabled = false;
              useBonjour = false;
              useBroadcastBSSID = true;
            };

            com.apple.alf = {
              allowdownloadsignedenabled = true;
              allowsignedenabled = true;
              applications = [];
              exceptions = [
                { path = "/usr/libexec/configd"; state = 3; }
                { path = "/usr/sbin/mDNSResponder"; state = 3; }
                { path = "/usr/sbin/racoon"; state = 3; }
                { path = "/usr/bin/nmblookup"; state = 3; }
                { path = "/System/Library/PrivateFrameworks/Admin.framework/Versions/A/Resources/readconfig"; state = 3; }
                { path = "/usr/libexec/discoveryd"; state = 3; }
                { path = "/usr/libexec/bootpd"; state = 3; }
                { path = "/usr/libexec/xartstorageremoted"; state = 3; }
                { bundleid = "com.apple.EmbeddedOSInstallService"; path = "/System/Library/PrivateFrameworks/EmbeddedOSInstall.framework/Versions/A/XPCServices/EmbeddedOSInstallService.xpc/"; state = 3; }
              ];
              explicitauths = [
                { id = "org.python.python.app"; }
                { id = "com.apple.ruby"; }
                { id = "com.apple.a2p"; }
                { id = "com.apple.javajdk16.cmd"; }
                { id = "com.apple.php"; }
                { id = "com.apple.nc"; }
                { id = "com.apple.ksh"; }
              ];
              firewall = {
                "Apple Remote Desktop" = { proc = "AppleVNCServer"; state = 1; }; # Enable VNC/Remote Desktop
                "FTP Access" = { proc = "ftpd"; state = 1; }; # Enable FTP
                "Personal File Sharing" = { proc = "AppleFileServer"; state = 1; }; # Enable File Sharing
                "Personal Web Sharing" = { proc = "httpd"; state = 1; }; # Enable Web Sharing
                "Printer Sharing" = { proc = "cupsd"; state = 1; }; # Enable Printer Sharing
                "Remote Apple Events" = { proc = "eppc"; state = 1; }; # Enable Remote Apple Events
                "Remote Login - SSH" = { proc = "sshd"; state = 1; }; # Enable SSH
                "Secure Web Sharing" = { proc = "httpd"; state = 1; }; # Enable Secure Web Sharing
                "Windows Sharing" = { proc = "smbd"; state = 1; }; # Enable SMB/Windows Sharing
              };
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
          # version = 12;
        };

      ControlCenterPreferences = {
        "com.apple.controlcenter" = {
          "LastHeartbeatDateString.daily" = "2024-06-02T22:37:27Z";
          "NSStatusItem Preferred Position AudioVideoModule" = 602;
          "NSStatusItem Preferred Position Battery" = 284;
          "NSStatusItem Preferred Position BentoBox" = 44;
          "NSStatusItem Preferred Position Bluetooth" = 116;
          "NSStatusItem Preferred Position FocusModes" = 223;
          "NSStatusItem Preferred Position NowPlaying" = 190;
          "NSStatusItem Preferred Position UserSwitcher" = 326;
          "NSStatusItem Preferred Position WiFi" = 78;
          "NSStatusItem Visible AudioVideoModule" = 1;
          "NSStatusItem Visible Battery" = 1;
          "NSStatusItem Visible BentoBox" = 1;
          "NSStatusItem Visible Bluetooth" = 1;
          "NSStatusItem Visible Clock" = 1;
          "NSStatusItem Visible FaceTime" = 1;
          "NSStatusItem Visible FocusModes" = 1;
          "NSStatusItem Visible Item-0" = 0;
          "NSStatusItem Visible Item-1" = 0;
          "NSStatusItem Visible Item-2" = 0;
          "NSStatusItem Visible Item-3" = 0;
          "NSStatusItem Visible Item-4" = 0;
          "NSStatusItem Visible Item-5" = 0;
          "NSStatusItem Visible Item-6" = 0;
          "NSStatusItem Visible Item-7" = 0;
          "NSStatusItem Visible Item-8" = 0;
          "NSStatusItem Visible NowPlaying" = 1;
          "NSStatusItem Visible UserSwitcher" = 1;
          "NSStatusItem Visible WiFi" = 1;
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
          isAutoHide = 0; # false so I can toggle?
          isAutoStart = 0; # broke with sketchybar atm.
          isShowPreferences = 0;
          numberOfSecondForAutoHide = 10;
          useFullStatusBarOnExpandEnabled = 0;
        };
        "com.apple.desktopservices" = {
        # Avoid creating .DS_Store files on network or USB volumes
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      };
      LaunchServices.LSQuarantine = false; # Finally some air to breathe.
      magicmouse.MouseButtonMode = "TwoButton"; # allow left and right click when using magic mouse.
      screencapture = {
        disable-shadow = true; # Disable Shadow in Screenshots
        location = "~/Desktop/Screenshots"; # Change Default Screenshot Location
        type = "png";
        "include-date" = true; # Include date in screenshot file names
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
};
}
