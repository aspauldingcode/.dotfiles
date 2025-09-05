{
  inputs,
  pkgs,
  lib,
  config,
  nix-colors,
  user,
  ...
}: let
  sopsConfig = import ../../../sops-nix/sopsConfig.nix {
    nixpkgs = inputs.nixpkgs;
    user = "alex";
    environment = "development";
    hostname = "NIXY";
  };
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    sopsConfig.hmSopsConfig
    nix-colors.homeManagerModules.default
    ../universals/modules
    ./home
    ./scripts
    ./modules
  ];

  # sops-nix templates are configured in sopsConfig.nix
}
