{ pkgs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-19.1.9"
      ];
      allowUnfreePredicate = (_: true);
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home = {
    packages = with pkgs; [
      # System utilities
      avahi
      libnotify
      busybox
      docker
      vscode
      fd
      gcal
      brightnessctl
      # box64 # not working with 16k pagesize m1 asahi
      gimp
      unstable.pmbootstrap
      jq
      lsof
      ncdu
      nmap
      pciutils
      ripgrep
      socat
      sshfs
      tigervnc
      usbmuxd
      wget
      xarchiver
      xz
      zip

      # Networking and communication
      android-tools
      checkra1n
      idevicerestore
      libimobiledevice
      libusb1
      libusbmuxd
      obsidian
      cmake
      rofi-wayland-unwrapped
      #zoom-us # NOT WORKING on aarch64-linux!

      # Multimedia and graphics
      blender
      brave
      cava
      ffmpeg-full
      flameshot
      kdePackages.kdenlive
      obs-studio
      obs-studio-plugins.obs-vkcapture
      #obs-studio-plugins.wlrobs # NOT WORKING on aarch64-linux!
      #spotify-unwrapped # NOT AVAILABLE on aarch64-linux!
      sway-contrib.grimshot
      yt-dlp # youtube-dl fork # MARKED INSECURE!
      # tartube-yt-dlp # GUI to use yt-dlp. MARKED INSECURE!

      # Desktop environment and window management
      albert
      autotiling
      bemenu
      clipman
      eww
      glpaper
      gnomeExtensions.dark-variant
      gtk-layer-shell
      i3status-rust
      imv
      lavalauncher
      lxappearance
      pcmanfm
      pinentry-bemenu
      swaybg
      swaylock-effects
      swayr
      swayrbar
      wbg
      wev
      wl-clipboard
      wl-screenrec
      wlroots
      wlogout
      wl-gammactl
      wlr-randr
      gammastep
      wl-gammarelay-rs
      wofi
      wshowkeys
      wtype
      wob
      pamixer

      # Gaming and emulation
      # android-studio # DOESN'T WORK ON aarch64-linux!
      element
      element-desktop
      #wineasio # NOT WORKING on asahi!
      # wineWow64Packages.waylandFull # NOT WORKING on aarch64-linux!
      winetricks

      # Fonts and theming
      corefonts
      glib
      sassc

      # Miscellaneous
      #beeper # DOESN'T WORK ON aarch64-linux!
      lolcat
      pfetch
      ruby_3_3
      sl
      thefuck
      waypipe
      wayvnc
      lavat

      (python311.withPackages (
        ps: with ps; [
          toml
          python-lsp-server
          pyls-isort
          flake8
          evdev
          pynput
          pygame
          matplotlib
          libei
          keyboard
          sympy
          numpy
          i3ipc
        ]
      ))

      (prismlauncher.override {
        jdks = [
          jdk8
          jdk21
        ];
      })
    ];
  };
}
