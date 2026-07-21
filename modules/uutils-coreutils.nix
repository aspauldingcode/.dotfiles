# uutils-coreutils (Rust) as the interactive/system coreutils on Darwin + NixOS.
#
# Installs `uutils-coreutils-noprefix` (unprefixed `ls`/`cat`/`timeout`/…) with
# `lib.hiPrio` so it wins over:
#   - macOS BSD tools in `/bin`
#   - GNU `coreutils` from other nix profiles
#   - busybox collisions
#
# We intentionally do NOT overlay `pkgs.coreutils` → uutils: that attribute is
# woven into stdenv and causes infinite recursion. Build-time
# `${pkgs.coreutils}/bin/…` references stay GNU; shells and PATH use uutils.
#
# GNU escape hatch (explicit): `pkgs.coreutils`
{ lib, ... }:
let
  uutils = pkgs: lib.hiPrio pkgs.uutils-coreutils-noprefix;

  mkSystem =
    { pkgs, ... }:
    {
      environment.systemPackages = [ (uutils pkgs) ];
    };

  mkHome =
    { pkgs, ... }:
    {
      home.packages = [ (uutils pkgs) ];
    };
in
{
  flake.modules.darwin.dendritic = mkSystem;
  flake.modules.nixos.dendritic = mkSystem;
  flake.modules.homeManager.dendritic = mkHome;
}
