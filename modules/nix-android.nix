# Wire [nix-android](https://github.com/devindudeman/nix-android) into this
# flake: androidConfigurations beside darwin/nixos, plus the pinned CLI.
#
# Controller systems only (upstream exports): aarch64-darwin, x86_64-linux.
# Phone ABI lives in hosts/android/oneplus6t — not here.
{ inputs, lib, ... }:
let
  deviceModule = ../hosts/android/oneplus6t;
  lockFile = ../hosts/android/oneplus6t/apps.lock.json;

  # nix-android ships controller packages for these systems only (LIMITS.md).
  controllerSystems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
in
{
  flake.androidConfigurations = {
    # Same phone declaration + lock; pick the output matching the machine
    # that runs adb.
    oneplus6t-darwin = inputs.nix-android.lib.mkDevice {
      system = "aarch64-darwin";
      modules = [ deviceModule ];
      inherit lockFile;
    };
    oneplus6t-linux = inputs.nix-android.lib.mkDevice {
      system = "x86_64-linux";
      modules = [ deviceModule ];
      inherit lockFile;
    };
  };

  perSystem =
    { system, ... }:
    lib.optionalAttrs (lib.elem system controllerSystems) {
      packages.android-rebuild = inputs.nix-android.packages.${system}.android-rebuild;

      apps.android-rebuild = {
        type = "app";
        program = "${inputs.nix-android.packages.${system}.android-rebuild}/bin/android-rebuild";
      };
    };
}
