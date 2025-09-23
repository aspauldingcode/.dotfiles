{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # System utilities
      avahi
      libnotify
      busybox
      docker
      vscode
      age
      sops
      fd
      gcal
      brightnessctl
      # box64 # not working with 16k pagesize m1 asahi
      gimp
      # unstable.pmbootstrap
      jq
      lsof
      ncdu
      nmap
      pciutils
      ripgrep
      socat
      sshfs
      nix-search
      tigervnc
      usbmuxd
      wget
      xarchiver
      xz
      zip

      # Networking and communication
      android-tools
      # checkra1n
      # idevicerestore
      # libimobiledevice
      # libusb1
      # libusbmuxd
      # obsidian
      # cmake
      # rofi-wayland-unwrapped
      # #zoom-us # NOT WORKING on aarch64-linux!
      #
      # # Multimedia and graphics
      # blender
      # cava
      # ffmpeg-full
      # flameshot
      # kdePackages.kdenlive
      # obs-studio
      obs-studio-plugins.obs-vkcapture
      #obs-studio-plugins.wlrobs # NOT WORKING on aarch64-linux!
      #spotify-unwrapped # NOT AVAILABLE on aarch64-linux!
      # Removed: sway-contrib.grimshot (Wayland-specific)

      # Desktop environment and window management
      bemenu
      clipman
      # gtk-layer-shell
      imv
      wl-clipboard
      wl-screenrec
      wl-gammarelay-rs
      wtype

      # Fonts and theming
      corefonts
      glib
      sassc

      # Miscellaneous
      # unstable.beeper # DOESN'T WORK ON aarch64-linux!
      sl
      waypipe
      wayvnc
      lavat

      (prismlauncher.override {
        jdks = [
          jdk8
          jdk21
        ];
      })
    ];
  };
}
