{ ... }:

{
  #enable brew packages just in case
  homebrew = {
    enable = true;
    onActivation = {
      #"zap" removes manually installed brews and casks
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
      "cava"
      "fftw" 
      "ncurses" 
      "libtool" 
      "automake" 
      "autoconf-archive" 
      "pkgconf"
      "portaudio"
      "iniparser"
      "gcal"
      "cliclick"
      "iproute2mac"
      "gtk-mac-integration" # build gtk mac apps?
    ];
    #masApps = [ #FAILS
      #497799835 #Xcode 
    #];
    casks = [
      #"xquartz" #what an ugly app
      "alacritty"
      "hammerspoon"
      "phoenix"
      "dmenu-mac"
      "macforge"
      "element"
      "brave-browser"
      "alt-tab"
      "standard-notes"
      "orbstack"
      "libreoffice"
      "karabiner-elements" # remap keyboard
      "unnaturalscrollwheels"
      "Beeper"
      "background-music"
      "sublime-text"
      "betterdiscord-installer"
      "discord"
      "asset-catalog-tinkerer"
      "themeengine"
    ];
    whalebrews = [
      #"wget" #FAILS
      #"whalesay" #FAILS
    ];
    taps = [
      #"user/repo"  # Additional Homebrew tap
      # default
      "homebrew/bundle"
      # "homebrew/cask"
      "homebrew/cask-fonts"
      # "homebrew/core"
      "homebrew/services"
      # Custom

      "koekeishiya/formulae"
      "FelixKratz/formulae"
    ];
  };
}
