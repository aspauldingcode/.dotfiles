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
      "libreoffice"
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
