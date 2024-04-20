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
      "yazi"
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
      # "meson"
      # "libev" #god dammit not working to compile i3 with gaps support
      #"okular" # FAILS
      #"dolphin" # FAILS
      #"ki18n" # FAILS
    ];
    #masApps = [ # FAILS
      #497799835 # Xcode 
    #];
    casks = [
      "xquartz" #what an ugly app
      "alacritty"
      "hammerspoon"
      "phoenix"
      "dmenu-mac"
      "kitty"
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
      "google-assistant"
      "gimp"
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
      "kde-mac/kde"
      "koekeishiya/formulae"
      "FelixKratz/formulae"
    ];
  };
}
