{ config, lib, pkgs, ... }:

{
  programs.vesktop = {
    enable = true;
    # Let Vesktop manage Vencord internally to avoid nixpkgs integration issues
    # See: https://github.com/NixOS/nixpkgs/issues/310227
  };
}
