# Enhanced Mobile NixOS configuration integrating phoneputer setup
# OnePlus 6T (fajita) configuration with phoneputer optimizations
{
  config,
  lib,
  pkgs,
  user,
  inputs,
  ...
}: {
  # Import mobile-nixos configuration
  imports = [
    # Mobile NixOS device configuration for OnePlus 6T
    (import "${inputs.mobile-nixos}/lib/configuration.nix" {device = "oneplus-fajita";})
  ];

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
    extraGroups = [
      "wheel"
      "audio"
    ];
    hashedPassword = "!";
  };

  # Enable GNOME Desktop Environment (from phoneputer)
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # Enable GNOME Keyring for password management
  services.gnome.gnome-keyring.enable = true;

  # Enable dconf for GNOME settings
  programs.dconf.enable = true;

  # Remove unwanted GNOME applications (from phoneputer)
  environment.gnome.excludePackages = with pkgs; [
    baobab # disk usage analyzer
    cheese # photo booth
    eog # image viewer
    epiphany # web browser
    simple-scan # document scanner
    totem # video player
    yelp # help viewer
    evince # document viewer
    file-roller # archive manager
    geary # email client
    seahorse # password manager
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-screenshot
    gnome-system-monitor
    gnome-weather
    gnome-disk-utility
    pkgs.gnome-connections
  ];

  # Essential packages combining both configurations
  environment.systemPackages = with pkgs; [
    # Core tools (from phoneputer)
    git
    vim
    neovim
    wget
    curl
    lazygit
    asciiquarium
    kitty

    # Mobile development tools
    android-tools # includes fastboot
    adb-sync

    # Mobile environment packages
    phosh
    phoc
    squeekboard
    calls
    chatty
    megapixels
    phosh-mobile-settings

    # Essential mobile utilities
    mobile-broadband-provider-info

    # Development and debugging tools
    htop
    gdb
    strace
    lsof
  ];

  # Mobile-specific services
  services = {
    # Core services
    dbus.enable = true;
    udev.enable = true;

    # Audio support with pipewire
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Location services
    geoclue2 = {
      enable = true;
      appConfig = {
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

  # Networking configuration is handled in local.nix
  # Explicitly disable NetworkManager to avoid conflict with wireless networking
  networking.networkmanager.enable = false;

  # Security and permissions
  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
  };

  # Mobile-specific hardware configuration
  hardware.sensor.iio.enable = true;

  # Allow insecure packages if needed
  nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];

  # Disable documentation generation to suppress mobile-nixos warnings
  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
  };

  # System state version
  system.stateVersion = "25.11";
}
