{ lib, config, pkgs, ... }:

# NIXSTATION-specific packages
{
  imports = [
    #../packages-UNIVERSAL.nix
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
      #allowUnfreePredicate = (_: true); #fixed with home-manager, needs fixing for configuration.nix system.
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
    checkra1n
    android-studio
    corefonts
    beeper
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
    avahi sshfs pcituis socat lolcat
    pmbootstrap libusb1 xarchiver logseq gimp zip
    sway-contrib.grimshot

    (prismlauncher.override {
	jdks = [ jdk8 jdk17 jdk19 ]; 
    })

    ];
  };
}

