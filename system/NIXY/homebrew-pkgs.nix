{ ... }:

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
      "x11vnc"
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
      "spicetify-cli"
      "cliclick"
      "iproute2mac"
      # "ruby@3.2"
      # "rbenv"
      # "ruby-build"
      "gtk-mac-integration" # build gtk mac apps?
      "whalebrew"
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
      "xquartz" # what an ugly app
      "alacritty"
      "hammerspoon"
      "phoenix"
      "prismlauncher"
      "dmenu-mac"
      "kitty"
      #"hiddenbar" #FIXME: disable for now, add back to build a working toggle.
      # "macforge" # out of date rn... need to use macforge beta
      "obs"
      "flameshot"
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
      #"google-assistant"
      "gimp"
      "docker"
    ];
    whalebrews = [
      #"wget" #FAILS
      # "whalesay" # FAILS
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
