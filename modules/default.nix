{ lib, ... }:
let
  # Auto-discover every *.nix file under this directory and import it as a
  # top-level flake-parts module. Files named `default.nix` (entrypoints) and
  # files whose basename starts with `_` (helpers/private fragments) are
  # skipped. This implements the Dendritic auto-import rule: every
  # non-entrypoint .nix file is a top-level module.
  isAutoImportable =
    path:
    let
      name = baseNameOf path;
    in
    lib.hasSuffix ".nix" name && name != "default.nix" && !lib.hasPrefix "_" name;

  autoImports = lib.filter isAutoImportable (lib.filesystem.listFilesRecursive ./.);
in
{
  imports = autoImports;
}
