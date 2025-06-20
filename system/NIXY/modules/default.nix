{ pkgs
, ...
}:

{
  imports = [
    ./defaults
    ./gowall
    # ./launch-agents
    ./launch-daemons
    # ./nix-the-planet
    ./openssh
    ./packages
    ./postActivation
    ./spicetify
    ./theme
    # ./wallpaper
    # ./wg-quick  # Commented out due to missing private key files
    ./windowManagement
  ];
}
