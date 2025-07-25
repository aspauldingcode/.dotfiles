{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home = {
      packages = with pkgs; [
        # Development tools
        arduino-language-server
        cmake-language-server
        jdt-language-server
        kotlin-language-server
        lua-language-server
        vscode
        quickemu
        quickgui

        # System utilities
        avahi
        debootstrap
        libnotify
        busybox
        docker
        fd
        gcal
        gimp
        home-manager
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
        unstable.checkra1n
        # idevicerestore  # Commented out due to libirecovery udev rules issue
        libimobiledevice
        libusb1
        libusbmuxd
        obsidian
        rofi-wayland-unwrapped
        zoom-us

        # Multimedia and graphics
        blender-hip
        brave
        cava
        ffmpeg-full
        flameshot
        kdePackages.kdenlive
        obs-studio
        obs-studio-plugins.obs-vkcapture
        obs-studio-plugins.wlrobs
        spotify-unwrapped
        sway-contrib.grimshot
        #yt-dlp # youtube-dl fork
        #tartube-yt-dlp # GUI to use yt-dlp

        # Desktop environment and window management
        albert
        autotiling
        bemenu
        clipman
        eww
        glpaper
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

        # Gaming and emulation
        android-studio
        element
        element-desktop
        wineasio
        wineWow64Packages.waylandFull
        winetricks
        heroic

        # Fonts and theming
        corefonts
        glib
        sassc

        # Miscellaneous
        beeper
        lolcat
        pfetch
        ruby_3_3
        sl
        thefuck
        waypipe
        wayvnc
        lavat
        tt

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
            jdk17
            # jdk19
            jdk21
            # Minecraft requires jdk21 SOON!
          ];
        })
      ];
    };
  };
}
