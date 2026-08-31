# Force-eval host/HM outputs for *this* system at `nix flake check`.
# Other-system configs are skipped: sliceanddice Stylix wallpaper is IFD and
# cannot build x86_64-linux derivations on Darwin without a linux builder.
{
  self,
  lib,
  ...
}:
let
  drv = x: builtins.unsafeDiscardStringContext x.config.system.build.toplevel.drvPath;
  hmDrv = x: builtins.unsafeDiscardStringContext x.activationPackage.drvPath;
  onSystem =
    system: c:
    (c.pkgs.stdenv.hostPlatform.system or c.config.nixpkgs.hostPlatform.system or "") == system;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      darwin = lib.filterAttrs (_: onSystem system) self.darwinConfigurations;
      nixos = lib.filterAttrs (_: onSystem system) self.nixosConfigurations;
      homes = lib.filterAttrs (
        _: c: (c.pkgs.stdenv.hostPlatform.system or "") == system
      ) self.homeConfigurations;
      lines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: c: "darwin.${n} ${drv c}") darwin
        ++ lib.mapAttrsToList (n: c: "nixos.${n} ${drv c}") nixos
        ++ lib.mapAttrsToList (n: c: "home.${n} ${hmDrv c}") homes
      );
    in
    {
      checks.hosts-eval = pkgs.writeText "dendritic-hosts-eval" (
        if lines == "" then "# no hosts for ${system}\n" else lines + "\n"
      );
    };
}
