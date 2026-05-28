# Make every system build depend on `checks.<system>.treefmt`.
#
# Why this exists: `treefmt-nix.flakeModule` already wires up
# `checks.<system>.treefmt` as a flake check, so `nix flake check` fails
# on unformatted files. But `darwin-rebuild switch`, `nh darwin switch`,
# `nixos-rebuild switch`, `nh os switch`, and plain
# `nix build .#darwinConfigurations.<host>.config.system.build.toplevel`
# all build ONLY the toplevel derivation — never the checks. That means
# you can rebuild a system in an unformatted state, which defeats "the
# repo is always formatted" as an invariant.
#
# Fix: drop a single `/etc/.dotfiles-treefmt-check` entry whose `source`
# is the per-system treefmt check derivation. Because every
# `environment.etc.<name>.source` becomes a hard build dependency of
# `system.build.toplevel`, the toplevel now transitively depends on the
# check passing. If `treefmt --ci` finds an unformatted file, the check
# build fails, which propagates up and the system build fails too —
# exactly mirroring `nix flake check`'s behaviour but at rebuild time.
#
# Cost: one /etc symlink (~0 bytes runtime) pointing at the check's empty
# `$out` marker.
{ inputs, ... }:
let
  mkTreefmtBuildDep =
    { pkgs, ... }:
    {
      environment.etc.".dotfiles-treefmt-check" = {
        source = inputs.self.checks.${pkgs.stdenv.hostPlatform.system}.treefmt;
      };
    };
in
{
  flake.modules.darwin.dendritic = mkTreefmtBuildDep;
  flake.modules.nixos.dendritic = mkTreefmtBuildDep;
}
