{
  lib,
  config,
  pkgs,
  ...
}:

# NIXY-specific packages
{
  imports = [
    ../packages-UNIVERSAL.nix
  ];
  home.packages = with pkgs; [
    # magnet?

  ];
}
