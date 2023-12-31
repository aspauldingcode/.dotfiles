
{ lib, config, pkgs, ... }:

# NIXSTATION-specific packages
{
  imports = [
  ]; 
  #FIXME: THEME STUFF
  gtk.enable = true;
  qt.enable = false;

  # QT theme
  qt.platformTheme = "gtk";

  # name of gtk theme
  qt.style.name = "adwaita-dark";

  # cursor theme
  #package = pkgs.bibata-cursors;
  #name = "Bibata-Modern-Ice";
  #size = 22;

  # package to use
  qt.style.package = pkgs.adwaita-qt;

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-19.1.9"
      ];
    };
  };

  home = {
    pointerCursor = {
      gtk.enable = true;
      # cursor theme
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 22;
    };
    
    packages = with pkgs; [
      lsof
      etcher
      checkra1n
      pfetch
      zoom-us
      spotify-unwrapped
      android-studio
      corefonts
      beeper
      # davinci-resolve 
      ocl-icd
      rofi-wayland-unwrapped
      vscode
      bemenu
      #wofiPower
      #wofiWindowJump
      #dunst
      eww-wayland
      glpaper
      gtk-layer-shell
      i3status-rust
      imv
      gpm
      lavalauncher
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-vkcapture
      swayr
      swayrbar
      #sway-unwrapped
      swaybg
      #swayidle
      #swaylock
      swaylock-effects
      #swww
      pinentry-bemenu
      waypipe
      #wayprompt
      wayvnc
      wbg
      wev
      #wf-recorder
      wl-clipboard
      wl-gammactl
      gammastep
      geoclue2
      wl-screenrec
      wlogout
      wlroots
      wlsunset
      wofi
      wshowkeys
      wtype
      clipman
      #etcher
      element-desktop
      blender
      brave
      transmission-gtk
      calcurse
      delta 
      gnupg
      audacity
      pinentry 
      git-crypt
      discord
      cowsay
      spotify-unwrapped
      autotiling waydroid
      pcmanfm 
      w3m 
      obs-studio
      audacity 
      razergenie
      docker 
      home-manager
      android-tools 
      xz 
      element
      OVMF
      edk2
      busybox
      #LSP PACKAGES for NVIM 
      ##NOTWORKING?!!?!?!?!? FIXME
      #rnix-lsp
      # FIND MORE INFO: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
      nil
      nodePackages_latest.typescript-language-server
      nodePackages_latest.typescript
      nodePackages_latest.pyright
      nodePackages_latest.bash-language-server
      nodePackages.yaml-language-server
      nodePackages_latest.dockerfile-language-server-nodejs
      jdt-language-server
      kotlin-language-server
      lua-language-server
      cmake-language-server
      arduino-language-server
      nodePackages_latest.vim-language-server
      #python311Packages.python-lsp-server
      blueman 
      jq 
      flameshot 
      fd 
      ripgrep
      linuxKernel.packages.linux_latest_libre.openrazer
      openrazer-daemon
      idevicerestore 
      usbmuxd 
      libusbmuxd 
      libimobiledevice
      avahi 
      sshfs 
      pciutils 
      socat 
      lolcat
      pmbootstrap 
      libusb1 
      xarchiver 
      gimp 
      zip
      thefuck
      sway-contrib.grimshot
      (python311.withPackages(ps: with ps; [
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
      ]))
      (prismlauncher.override {
        jdks = [ jdk8 jdk17 jdk19 ]; 
      })
      #fix-wm
      (pkgs.writeShellScriptBin "fix-wm" ''
        pkill waybar && sway reload
      '')
    ];
  };
}
