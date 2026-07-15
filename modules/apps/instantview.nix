# Silicon Motion macOS InstantView — upstream nixpkgs only.
#
# Package: `pkgs.macos-instantview` (overlaid from nixpkgs-unstable →
# 3.24R0004 / nixpkgs#530053). 26.05 still carries 3.22R0002.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkIf pkgs.stdenv.isDarwin {
        home.packages = [ pkgs.macos-instantview ];
      };
    };
}
