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
      # "borders" SUUUPER JANKY!
      "yazi"
      "cava"
      "fftw"
      "ncurses"
      "libtool"
      "automake"
      "autoconf-archive"
      "nightlight"
      # "pkgconf"
      "portaudio"
      "iniparser"
      "gcal"
      "spicetify-cli"
      "zenity"
      "cliclick"
      "iproute2mac"
      # "ruby@3.2"
      # "rbenv"
      # "ruby-build"
      "gtk-mac-integration" # build gtk mac apps?
      "libiconv"
      "whalebrew"
      # "meson"
      # "libev" #god dammit not working to compile i3 with gaps support
      #"okular" # FAILS
      #"dolphin" # FAILS
      #"ki18n" # FAILS
      "ddcctl"
    ];
    #masApps = [ # FAILS
    #497799835 # Xcode 
    #];
    casks = [
      "xquartz" # what an ugly app
      "alacritty"
      "chatgpt"
      "hammerspoon"
      "phoenix"
      "prismlauncher"
      "dmenu-mac"
      "kitty"
      "krita"
      "spotify"
      #"hiddenbar" #FIXME: disable for now, add back to build a working toggle.
      # "macforge" # out of date rn... need to use macforge beta
      "obs"
      "obs-websocket"
      "flameshot"
      "element"
      "brave-browser"
      "firefox"
      "alt-tab"
      "orbstack"
      "libreoffice"
      "karabiner-elements" # remap keyboard
      "unnaturalscrollwheels"
      "Beeper"
      "background-music" # audio routing driver. Fixes cava, but not working.
      "sublime-text"
      "asset-catalog-tinkerer"
      "themeengine"
      "docker"
      "kdeconnect"
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
      "smudge/smudge"
    ];
  };
}
