{
  config,
  pkgs,
  lib,
  ...
}:
import ./eduroam.nix {inherit config pkgs lib;}
