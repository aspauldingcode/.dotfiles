{ ... }:

{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "alex";
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-bundle" = homebrew-bundle;
      "homebrew/homebrew-services" = homebrew-services;
      "koekeishiya/homebrew-formulae" = homebrew-koekeishiya;
      "FelixKratz/homebrew-formulae" = homebrew-felixkratz;
      "smudge/homebrew-smudge" = homebrew-smudge;
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
      "xinit"
      "x11vnc"
      "xorg-server"
      "choose-gui"
      "yazi"
      "cava"
      "fftw"
      "ncurses"
      "libtool"
      "automake"
      "autoconf-archive"
      "nightlight"
      "portaudio"
      "iniparser"
      "zenity"
      "cliclick"
      "iproute2mac"
      "m-cli"
      "ansible"
      "gtk-mac-integration"
      "libiconv"
      "whalebrew"
      "ddcctl"
    ];

    casks = [
      "arduino-ide"
      "chatgpt"
      "pppc-utility"
      "prismlauncher"
      "kitty"
      "krita"
      "hiddenbar"
      "obs"
      "obs-websocket"
      "cursor"
      "brave-browser"
      "alt-tab"
      "azure-data-studio"
      "orbstack"
      "libreoffice"
      "karabiner-elements"
      "unnaturalscrollwheels"
      "Beeper"
      "desktoppr"
      "background-music"
      "sublime-text"
      "asset-catalog-tinkerer"
      "themeengine"
      "docker"
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
