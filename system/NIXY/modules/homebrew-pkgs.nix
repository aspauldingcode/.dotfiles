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
      # "yabai"
      # "skhd"
      # "sketchybar"
      # "borders" #SUUUPER JANKY! Compile from master for now.
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
      # "gcal" # GONER!
      "zenity"
      "cliclick"
      "iproute2mac"
      "m-cli"
      "ansible"
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
      # "xquartz" # what an ugly app
      "alacritty"
      "chatgpt"
      "pppc-utility"
      "prismlauncher"
      #"dmenu-mac" # USE UNMENU FORK!
      "kitty"
      "krita"
      "hiddenbar" #FIXME: disable for now, add back to build a working toggle.
      # "macforge" # out of date rn... need to use macforge beta
      "obs"
      "obs-websocket"
      "cursor"
      "brave-browser"
      "firefox"
      "alt-tab"
      "azure-data-studio"
      "orbstack"
      "libreoffice"
      "karabiner-elements" # remap keyboard
      "unnaturalscrollwheels"
      "Beeper"
      "desktoppr"
      "background-music" # audio routing driver. Fixes cava, but not working.
      "sublime-text"
      "asset-catalog-tinkerer"
      "themeengine"
      "docker"
      #"kdeconnect"
    ];
    whalebrews = [
      #"wget" #FAILS
      # "whalesay" # FAILS
    ];
    taps = [
      #"user/repo"  # Additional Homebrew tap
      # default
      "homebrew/bundle"
      "homebrew/services"
      # Custom
      #"kde-mac/kde" # FIXME: Fails at first install.. you must visit https://github.com/KDE/homebrew-kde to install correctly.
      "koekeishiya/formulae"
      "FelixKratz/formulae"
      "smudge/smudge"
    ];

    masApps = {
      "Xcode" = 497799835; 
      # then need to run:
      # sudo xcodebuild -license accept
      # to accept the license.
    };
  };
  # fix xcode license and run first launch.
  system.activationScripts.postUserActivation.text = ''
    sudo xcode-select -s /Applications/Xcode.app
    sudo xcodebuild -license accept
    xcodebuild -runFirstLaunch
  '';
}
