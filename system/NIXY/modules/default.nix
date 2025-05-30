{
  pkgs,
  ...
}:

{
  imports = [
    ./defaults
    ./dock
    ./gowall
    ./launch-agents
    # ./launch-daemons
    # ./nix-the-planet
    ./openssh
    ./packages
    ./postActivation
    ./spicetify
    ./theme
    ./wallpaper
    ./wg-quick
    ./windowManagement
  ];
}
