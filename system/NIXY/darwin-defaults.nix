{ ... }:

##SYSTEM DEFAULTS!!!! MACOS defaults config.
{
  system.defaults = {
    finder = { 
      CreateDesktop = false;
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
      LoginwindowText = "NIXY"; 
      PowerOffDisabledWhileLoggedIn = false;
      RestartDisabled = false;
      RestartDisabledWhileLoggedIn = false;
      SleepDisabled = false;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # or null; for normal. ##FIXME: TRIGGER WITH COLORSCHEME!
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
    };
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true; # always up to date
    spaces = {
      spans-displays = false; # Required false for yabai!
    };
    dock = {
      autohide = true; 
      autohide-delay = 1000.0; #defaults write com.apple.dock autohide-delay -float 1000; killall Dock
      autohide-time-modifier = 0.001; # or null?
      dashboard-in-overlay = true;
      expose-animation-duration = 0.001; #or null?
      expose-group-by-app = null;
      launchanim = false;
      orientation = "bottom";
      show-recents = false;
      showhidden = true;
      wvous-bl-corner = 1; # 1 for disable
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    }; 
    menuExtraClock.IsAnalog = true;
    trackpad = {
      ActuationStrength = 0; # silent clicking
      Clicking = false; # tap to click
      Dragging = true; # tap to drag
      TrackpadRightClick = true;
      # TrackpadThreeFingerDrag = true;
    };
    universalaccess = {
      mouseDriverCursorSize = 1.2; # Cursor size
      reduceMotion = true;
      reduceTransparency = true; 
    };
    ".GlobalPreferences" = {
      "com.apple.mouse.scaling" = 8.0; # Set to -1.0 to disable mouse acceleration.
    };
  };
}