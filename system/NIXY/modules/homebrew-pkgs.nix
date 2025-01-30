{ inputs, ... }:

{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "alex";
    mutableTaps = false;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-services" = inputs.homebrew-services;
      "koekeishiya/homebrew-formulae" = inputs.homebrew-koekeishiya;
      "FelixKratz/homebrew-formulae" = inputs.homebrew-felixkratz;
      "smudge/homebrew-smudge" = inputs.homebrew-smudge;
      # "gcenx/wine" = inputs.homebrew-gcenx; # FIXME: This is not working on first-install.
      # "kde-mac/kde" = inputs.homebrew-kde;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    brews = [
      "x11vnc"
      "nightlight"
      "choose-gui"
      "xinit"
      "xorg-server"
      # "yazi"
      # "fftw"
      # "ncurses"
      # "libtool"
      # "automake"
      # "autoconf-archive"
      # "portaudio"
      # "iniparser"
      # "zenity"
      # "iproute2mac"
      # "m-cli"
      # "ansible"
      # "gtk-mac-integration"
      "libiconv"
      "cliclick"
      "whalebrew"
      "ddcctl"
      "winetricks"
      # KDE Framework 6 dependencies
      # "kde-mac/kde/kf6-kcmutils"
      # "kde-mac/kde/kf6-knewstuff"
      # "kde-mac/kde/kf6-kcoreaddons"
      # "kde-mac/kde/kf6-ki18n"
      # "kde-mac/kde/kf6-kdbusaddons"
      # "kde-mac/kde/kf6-kbookmarks"
      # "kde-mac/kde/kf6-kconfig"
      # "kde-mac/kde/kf6-kio"
      # "kde-mac/kde/kf6-kparts"
      # "kde-mac/kde/kf6-solid"
      # "kde-mac/kde/kf6-kiconthemes"
      # "kde-mac/kde/kf6-kcompletion"
      # "kde-mac/kde/kf6-ktextwidgets"
      # "kde-mac/kde/kf6-knotifications"
      # "kde-mac/kde/kf6-kcrash"
      # "kde-mac/kde/kf6-kwindowsystem"
      # "kde-mac/kde/kf6-kwidgetsaddons"
      # "kde-mac/kde/kf6-kcodecs"
      # "kde-mac/kde/kf6-guiaddons"
    ];

    casks = [
      "arduino-ide"
      "chatgpt"
      "gittyup"
      "pppc-utility"
      "krita"
      "kdenlive"
      "hiddenbar"
      "obs"
      "obs-websocket"
      "cursor" # FIXME: I've created PR for this to be in nixpkgs. https://github.com/NixOS/nixpkgs/pull/371260
      "azure-data-studio"
      "orbstack"
      #"libreoffice" # FIXME: breaks sometimes? wth
      "karabiner-elements"
      "Beeper"
      "background-music"
      "sublime-text"
      "themeengine"
      "wine-stable"
      #{
      #  name = "gcenx/wine/kegworks";
      #  args = { no_quarantine = true; };
      #}
    ];

    masApps = {
      "Xcode" = 497799835;
    };
  };

  system.activationScripts.postUserActivation.text = ''
    sudo xcode-select -s /Applications/Xcode.app
    sudo xcodebuild -license accept
    xcodebuild -runFirstLaunch
  '';
}
