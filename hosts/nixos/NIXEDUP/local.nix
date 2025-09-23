# Minimal configuration for OnePlus 6T (fajita) NixOS Mobile
# Focus on essentials: SSH, wireless, and basic tools
{
  pkgs,
  ...
}:
{
  # Allow unfree packages (needed for OnePlus firmware)
  nixpkgs.config.allowUnfree = true;

  # Disable boot control to avoid Ruby/Perl build issues during cross-compilation
  mobile.boot.boot-control.enable = false;

  # Enable SSH server (essential for mobile device access)
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes"; # For initial setup
  services.openssh.settings.PasswordAuthentication = true; # For initial setup

  # Hardcoded WiFi configuration
  networking.wireless = {
    enable = true;
    networks = {
      # Replace these with your actual WiFi credentials
      "YourWifi" = {
        psk = "WifiPassword123"; # Must be 8-63 characters
      };
    };
  };

  # Set root password for SSH access
  users.users.root.password = "nixtheplanet";

  # Minimal essential packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
}
