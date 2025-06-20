{
  inputs,
  pkgs,
  lib,
  nix-colors,
  user,
  ...
}:

{
  imports = [
    nix-colors.homeManagerModules.default
    ../universals/modules
    ./home
    ./scripts
    ./modules
  ];
}
