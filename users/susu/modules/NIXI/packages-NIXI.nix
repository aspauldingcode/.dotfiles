{
  lib,
  config,
  pkgs,
  ...
}:
# NIXI-specific packages (Intel Mac)
{
  imports = [
    ../packages-UNIVERSAL.nix
  ];
  home.packages = with pkgs; [
    # Intel Mac specific packages can go here
    # Avoid packages that don't support x86_64-darwin
  ];
}