
{ lib, config, pkgs, ... }:

# NIXSTATION-specific packages
{
  imports = [
  ]; 
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
      zoom-us
      spotify-unwrapped
      android-studio
      corefonts
      beeper
      davinci-resolve ocl-icd
      rofi-wayland-unwrapped
      #wofiPower
      #wofiWindowJump
      #aml
      #cage
      #drm_info
      #dunst
      #eww
      eww-wayland
#foot
#freerdp3
#gebaar-libinput
glpaper
#grim
gtk-layer-shell
i3status-rust
imv
#kanshi
lavalauncher
#libvncserver_master
#mako
neatvnc
#new-wayland-protocols
obs-studio-plugins.wlrobs
obs-studio-plugins.obs-vkcapture
rootbar
#salut
#shotman
#sirula
#slurp
#sway-unwrapped
swaybg
#swayidle
#swaylock
swaylock-effects
#swww
#waybar
waypipe
#wayprompt
wayvnc
wbg
#wdisplays
wev
#wf-recorder
wl-clipboard
wl-gammactl
#wl-gammarelay-rs
wl-screenrec
#wlay
#wldash
wlogout
#wlr-randr
wlroots
wlsunset
#wlvncc
#wob
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
    delta gnupg audacity
    pinentry 
    git-crypt
    discord
    cowsay
    spotify-unwrapped
    autotiling waydroid
    pcmanfm w3m obs-studio
    audacity razergenie
    docker home-manager
    android-tools xz element
    OVMF
    edk2
    #LSP PACKAGES for NVIM 
    ##NOTWORKING?!!?!?!?!? FIXME
    rnix-lsp
    nodePackages_latest.typescript-language-server
    nodePackages_latest.typescript
    nodePackages_latest.pyright
    nodePackages_latest.bash-language-server
    nodePackages.yaml-language-server
    nodePackages_latest.dockerfile-language-server-nodejs
    java-language-server
    jdt-language-server
    kotlin-language-server
    lua-language-server
    cmake-language-server
    arduino-language-server
    nodePackages_latest.vim-language-server
    #python311Packages.python-lsp-server

    blueman jq flameshot fd ripgrep
    linuxKernel.packages.linux_latest_libre.openrazer
    openrazer-daemon
    idevicerestore usbmuxd libusbmuxd libimobiledevice
    avahi sshfs pciutils socat lolcat
    pmbootstrap libusb1 xarchiver gimp zip
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
    ]))
    (prismlauncher.override {
      jdks = [ jdk8 jdk17 jdk19 ]; 
    })
  ];
};
}
