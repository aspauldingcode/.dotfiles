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
      "sublime-text"
    ];
    #masApps = [ #FAILS
      #497799835 #Xcode 
    #];
    casks = [
      #"xquartz" #what an ugly app
      "alacritty"
      "dmenu-mac"
      "element"
      "brave-browser"
      "alt-tab"
      "orbstack"
      "karabiner-elements" # remap keyboard
      "unnaturalscrollwheels"
      "Beeper"
      "background-music"
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
