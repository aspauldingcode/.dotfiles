{ ... }:
{
  imports = [
    ./defaults
    ./gowall
    # ./launch-agents
    ./launch-daemons
    # ./nix-the-planet
    ./openssh
    ./packages
    ./macos-settings
    # ./postActivation  # Moved to shared/scripts/post-activation.nix
    # ./spicetify  # Moved to home-manager configuration
    ./theme
    # ./wallpaper
    # ./wg-quick  # Commented out due to missing private key files
    ./windowManagement
  ];
}
