{
  inputs,
  pkgs,
  nix-colors,
  lib,
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
