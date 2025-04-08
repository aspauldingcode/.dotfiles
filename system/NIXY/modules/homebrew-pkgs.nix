{ inputs, ... }:

{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "alex";
    mutableTaps = false;
    autoMigrate = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-services" = inputs.homebrew-services;
      "koekeishiya/homebrew-formulae" = inputs.homebrew-koekeishiya;
      "FelixKratz/homebrew-formulae" = inputs.homebrew-felixkratz;
      "smudge/homebrew-smudge" = inputs.homebrew-smudge;
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
      "nightlight"
      "ddcctl"
      "choose-gui"
      #"libiconv"
    ];

    casks = [
      # "arduino-ide" # I don't have storage space for this
      # "android-studio" # I don't have storage space for this
      # "krita" # I don't have storage space for this
      # "kdenlive" # I don't have storage space for this
      # "heroic" # I don't have storage space for this
      # "azure-data-studio"
      #"libreoffice" # FIXME: breaks sometimes? wth
      "karabiner-elements"
      "Beeper"
    ];

    masApps = {
      "Xcode" = 497799835;
      "Windows App" = 1295203466;
    };
  };

  system.activationScripts.postUserActivation.text = ''
    sudo xcode-select -s /Applications/Xcode.app
    sudo xcodebuild -license accept
    xcodebuild -runFirstLaunch
  '';
}
