# SOPS Module - Secrets management configuration
{inputs, ...}: let
  # Import SOPS configurations
  sopsConfigs = import ../sops-nix/sopsConfig.nix {
    nixpkgs = inputs.nixpkgs;
    user = "alex";
    # Don't set a default environment here - let each system specify it
  };
in {
  flake.sopsConfigs = sopsConfigs;
}
