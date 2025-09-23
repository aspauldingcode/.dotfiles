# NIXY Darwin Configuration
# aarch64 Darwin (Apple Silicon) macOS System
{
  hostname,
  ...
}:
{
  imports = [
    ../../../../shared/base/darwin-base.nix
    ../modules
  ];

  # System-specific networking using passed hostname
  networking = {
    computerName = hostname;
    hostName = hostname;
    localHostName = hostname;
  };

  # System-specific nixpkgs configuration
  nixpkgs.hostPlatform = "aarch64-darwin";
}
