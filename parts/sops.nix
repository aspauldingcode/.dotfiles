# SOPS Module - Secrets management configuration
{ inputs, ... }:
let
  # Import SOPS configurations
  sopsConfigs = import ../sops-nix/sopsConfig.nix {
    nixpkgs = inputs.nixpkgs;
    user = "alex";
  };
in
{
  flake.sopsConfigs = sopsConfigs;
}
