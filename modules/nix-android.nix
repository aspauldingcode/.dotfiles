# Wire [nix-android](https://github.com/devindudeman/nix-android) into this
# flake: androidConfigurations beside darwin/nixos, plus the pinned CLI and
# wireless adb helper. Phone ABI lives in hosts/android/oneplus6t.
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
    {
      system,
      pkgs,
      ...
    }:
    let
      onController = lib.elem system controllerSystems;
      adbWireless = pkgs.writeShellApplication {
        name = "adb-wireless";
        runtimeInputs = [ pkgs.android-tools ];
        text = ''
          exec bash ${../scripts/adb-wireless.sh} "$@"
        '';
      };
    in
    {
      packages =
        {
          adb-wireless = adbWireless;
        }
        // lib.optionalAttrs onController {
          android-rebuild = inputs.nix-android.packages.${system}.android-rebuild;
        };

      apps =
        {
          adb-wireless = {
            type = "app";
            program = "${adbWireless}/bin/adb-wireless";
          };
        }
        // lib.optionalAttrs onController {
          android-rebuild = {
            type = "app";
            program = "${inputs.nix-android.packages.${system}.android-rebuild}/bin/android-rebuild";
          };
        };
    };
}
