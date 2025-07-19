{
  inputs,
  lib,
  config,
  pkgs,
  mobile-nixos,
  user,
  ...
}:
{
  imports = [
    # Use the enhanced phoneputer integration
    ./phoneputer-integration.nix
    ./local.nix
  ];
}
