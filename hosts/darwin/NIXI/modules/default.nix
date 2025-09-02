{pkgs, ...}: {
  imports = [
    ./defaults
    ./gowall
    # ./launch-agents
    ./launch-daemons
    # ./nix-the-planet
    ./openssh
    ./packages
    ./macos-settings
    ./postActivation
    ./scripts
    ./spicetify
    ./theme
    # ./wallpaper
    # ./wg-quick  # Commented out due to missing private key files
    ./windowManagement
  ];
}
