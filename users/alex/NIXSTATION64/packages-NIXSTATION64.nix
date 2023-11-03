
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
      ncdu
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
      #wayrecorder
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
    jetbrains.idea-ultimate
    swayfx autotiling waydroid
    pcmanfm w3m obs-studio
    audacity razergenie
    docker home-manager
    android-tools xz element
    blueman jq flameshot fd ripgrep
    linuxKernel.packages.linux_latest_libre.openrazer
    openrazer-daemon
    idevicerestore usbmuxd libusbmuxd libimobiledevice
    avahi sshfs pciutils socat lolcat
    pmbootstrap libusb1 xarchiver logseq gimp zip
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
    ]))
    (prismlauncher.override {
      jdks = [ jdk8 jdk17 jdk19 ]; 
    })

  ];
};
}
