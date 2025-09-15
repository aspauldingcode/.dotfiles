{
  config,
  lib,
  users,
  ...
}: {
  nix-plist-manager = {
    enable = true;
    users = ["alex"];

    # System Settings Configuration
    systemSettings = {
      # Appearance
      appearance = {
        appearance = "Dark";
        accentColor = "Purple";
        sidebarIconSize = "Medium";
        allowWallpaperTintingInWindows = true;
        showScrollBars = "Always";
        clickInTheScrollBarTo = "Jump to the spot that's clicked";
      };

      # Control Center
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

      # Desktop & Dock
      desktopAndDock = {
        dock = {
          size = 48;
          magnification = {
            enabled = true;
            size = 64;
          };
          positionOnScreen = "Bottom";
          minimizeWindowsUsing = "Genie Effect";
          doubleClickAWindowsTitleBarTo = "Zoom";
          minimizeWindowsIntoApplicationIcon = false;
          automaticallyHideAndShowTheDock = {
            enabled = false;
            delay = 0.5;
            duration = 0.3;
          };
          animateOpeningApplications = true;
          showIndicatorsForOpenApplications = true;
          showSuggestedAndRecentAppsInDock = false;
        };

        desktopAndStageManager = {
          showItems = {
            onDesktop = true;
            inStageManager = false;
          };
          clickWallpaperToRevealDesktop = "Always";
          stageManager = false;
          showRecentAppsInStageManager = false;
          showWindowsFromAnApplication = "All at Once";
        };

        widgets = {
          showWidgets = {
            onDesktop = false;
            inStageManager = false;
          };
          widgetStyle = "Automatic";
          useIphoneWidgets = false;
        };

        windows = {
          preferTabsWhenOpeningDocuments = "In Full Screen";
          askToKeepChangesWhenClosingDocuments = true;
          closeWindowsWhenQuittingAnApplication = false;
          dragWindowsToScreenEdgesToTile = true;
          dragWindowsToMenuBarToFillScreen = true;
          holdOptionKeyWhileDraggingWindowsToTile = false;
          tiledWindowsHaveMargin = true;
        };

        missionControl = {
          automaticallyRearrangeSpacesBasedOnMostRecentUse = false;
          whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = true;
          groupWindowsByApplication = false;
          displaysHaveSeparateSpaces = true;
          dragWindowsToTopOfScreenToEnterMissionControl = false;
        };

        hotCorners = {
          topLeft = "-";
          topRight = "-";
          bottomLeft = "-";
          bottomRight = "-";
        };
      };

      # Focus
      focus = {
        shareAcrossDevices = true;
      };

      # General
      general = {
        softwareUpdate = {
          automaticallyDownloadNewUpdatesWhenAvailable = true;
          automaticallyInstallMacOSUpdates = false;
          automaticallyInstallApplicationUpdatesFromTheAppStore = true;
          automaticallyInstallSecurityResponseAndSystemFiles = true;
        };

        dateAndTime = {
          setTimeAndDateAutomatically = true;
          "24HourTime" = true;
          show24HourTimeOnLockScreen = true;
          setTimeZoneAutomaticallyUsingCurrentLocation = true;
        };
      };

      # Keyboard
      keyboard = {
        keyRepeatRate = 6;
        keyRepeatDelay = 2;
        adjustKeyboardBrightnessInLowLight = true;
        keyboardBrightness = 0.5;
        turnKeyboardBacklightOffAfterInactivity = "After 1 Minute";
        pressGlobeKeyTo = "Show Emoji & Symbols";
        keyboardNavigation = true;

        keyboardShortcuts = {
          functionKeys = {
            useF1F2EtcAsStandardFunctionKeys = false;
          };
        };

        dictation = {
          enabled = false;
        };
      };

      # Notifications
      notifications = {
        notificationCenter = {
          showPreviews = "When Unlocked";
          summarizeNotifications = false;
        };
      };
    };

    # Applications Configuration
    applications = {
      finder = {
        settings = {
          advanced = {
            showAllFilenameExtensions = true;
            removeItemsFromTheTrashAfter30Days = false;
          };
        };
      };
    };
  };
}
