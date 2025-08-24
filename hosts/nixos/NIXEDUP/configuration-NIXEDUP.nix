# NixOS Mobile configuration for OnePlus 6T (NIXEDUP)
# Based on phoneputer template: https://github.com/mwlaboratories/phoneputer
{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  # Allow unfree packages (needed for OnePlus firmware)
  nixpkgs.config.allowUnfree = true;

  # Disable boot control to avoid Ruby/Perl build issues during cross-compilation
  mobile.boot.boot-control.enable = false;

  # Enable SSH server (essential for mobile device access)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes"; # For initial setup
      PasswordAuthentication = true; # For initial setup
    };
  };

  # Set root password for SSH access
  users.users.root.password = "nixtheplanet";

  # Define the user for sops-nix secret ownership
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    hashedPassword = "!";
  };

  # Enable X11 for mobile-nixos compatibility
  services.xserver.enable = true;

  # Enable GNOME Keyring for password management
  services.gnome.gnome-keyring.enable = true;

  # Enable dconf for settings
  programs.dconf.enable = true;

  # Essential packages for mobile device
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    vim
    wget
    curl
    lazygit
    asciiquarium
    neovim
    kitty
    htop

    # Mobile tools
    android-tools
    adb-sync

    # Phosh and mobile environment packages
    phosh
    phoc
    squeekboard
    calls
    chatty
    megapixels
    phosh-mobile-settings

    # GNOME apps for mobile
    gnome-contacts
    gnome-calendar
    gnome-maps
    gnome-weather
    gnome-clocks
    gnome-calculator
    gnome-screenshot
    gnome-system-monitor

    # Mobile utilities
    mobile-broadband-provider-info
    networkmanager
    networkmanagerapplet
    modemmanager
    ofono

    # Development and debugging tools
    gdb
    strace
    lsof
  ];

  # Mobile-specific services
  services = {
    # Enable mobile-specific services
    dbus.enable = true;
    udev.enable = true;

    # Audio support
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Mobile-specific services
    geoclue2 = {
      enable = true;
      appConfig = {
        "gnome-photos" = {
          isAllowed = true;
          isSystem = true;
        };
        "megapixels" = {
          isAllowed = true;
          isSystem = true;
        };
        "gnome-maps" = {
          isAllowed = true;
          isSystem = true;
        };
      };
    };
  };

  # Enable NetworkManager for mobile networking
  networking.networkmanager.enable = true;

  # Security and permissions
  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
  };

  # Sops-nix secrets
  sops.secrets.wifi_bubbles_passwd = {};

  # Mobile-specific hardware configuration
  hardware.sensor.iio.enable = true;
  services.pulseaudio.enable = false; # Disabled in favor of pipewire

  # Allow insecure olm package (required by some mobile apps)
  nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];

  # System state version
  system.stateVersion = "25.11";
}
