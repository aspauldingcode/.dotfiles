{
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./scripts
    ./modules
    ./modules/windowManagement
    ./configuration
    # ./modules/nix-the-planet.nix
  ];
}
