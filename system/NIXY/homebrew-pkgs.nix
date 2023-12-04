{ lib, pkgs, config, ... }:

{
  #enable brew packages just in case
  homebrew = {
    enable = true;
    onActivation = {
      # "zap" removes manually installed brews and casks
        cleanup = "zap";
        autoUpdate = true;
        upgrade = true;
      };
    brews = [
      "xinit"
      "xorg-server"
      "choose-gui"
      "yabai"
      "skhd"
      "sketchybar"
      "borders"
    ];

    casks = [
    #"xquartz" #what an ugly app
    "dmenu-mac"
    "brave-browser"
    "alt-tab"
    "orbstack"
    "karabiner-elements" # remap keyboard
  ];

<<<<<<< HEAD
    #masApps = [ #FAILS
      #497799835 #Xcode 
    #];
=======
  casks = [
   #"xquartz" #what an ugly app
   "dmenu-mac"
   "brave-browser"
   "alt-tab"
   "orbstack"
   "karabiner-elements" # remap keyboard
   "unnaturalscrollwheels"
 ];
>>>>>>> f75894bc426fb7a61ad57f586d89b08cd27a8809

    whalebrews = [
      #"wget" #FAILS
      #"whalesay" #FAILS
    ];

    taps = [
      #"user/repo"  # Additional Homebrew tap
      # default
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/core"
      "homebrew/services"
      # Custom
      "koekeishiya/formulae"
      "FelixKratz/formulae"
    ];
  };
}
