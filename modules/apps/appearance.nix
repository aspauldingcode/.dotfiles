# dendritic-appearance — Rust activation-only light/dark sync (macOS + NixOS).
#
# Builds the cross-platform CLI and wires:
#   - PATH package
#   - Darwin: replace osascript detect; post-activate wallpaper+tint apply
#   - Linux: Waybar toggle module
#   - Prebuilt/specialisation activate helper (no rebuild)
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.appearance;
      appearancePkg = pkgs.rustPlatform.buildRustPackage {
        pname = "dendritic-appearance";
        version = "0.1.0";
        src = ./dendritic-appearance;
        cargoLock.lockFile = ./dendritic-appearance/Cargo.lock;
        meta = {
          description = "Dendritic light/dark + wallpaper activation sync";
          mainProgram = "dendritic-appearance";
        };
      };
    in
    {
      options.dendritic.appearance = {
        enable = lib.mkEnableOption "Rust dendritic-appearance sync CLI" // {
          default = config.dendritic.wallpaper.enable or false;
          defaultText = lib.literalExpression "config.dendritic.wallpaper.enable";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ appearancePkg ];

        # Expose pack-aware wallpaper binary path for the Rust tool.
        home.sessionVariables.DENDRITIC_WALLPAPER_BIN = lib.mkDefault "dendritic-wallpaper";
      };
    };

  # Darwin system: helpers that the Rust tool + launchd sync call (no osascript).
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      appearancePkg = pkgs.rustPlatform.buildRustPackage {
        pname = "dendritic-appearance";
        version = "0.1.0";
        src = ./dendritic-appearance;
        cargoLock.lockFile = ./dendritic-appearance/Cargo.lock;
        meta.mainProgram = "dendritic-appearance";
      };
    in
    {
      config = lib.mkIf (config.home-manager.users ? ${user}) {
        environment.systemPackages = [ appearancePkg ];

        # Fast-activate a prebuilt light/dark profile without rebuild.
        # Called by `dendritic-appearance set|toggle` after the hot-reload layer.
        environment.etc."dendritic-appearance-activate-prebuilt.sh".text = ''
          #!/bin/sh
          set -eu
          desired="''${1:-}"
          case "$desired" in light|dark) ;; *)
            echo "usage: $0 light|dark" >&2
            exit 2
          ;; esac

          state_dir="/var/lib/dendritic"
          path_file="$state_dir/prebuilt-$desired-path"
          if [ ! -f "$path_file" ]; then
            echo "dendritic-appearance: no prebuilt for $desired (run nh darwin switch once)" >&2
            exit 0
          fi
          prebuilt_path="$(cat "$path_file")"
          if [ ! -x "$prebuilt_path/activate" ]; then
            echo "dendritic-appearance: prebuilt missing activate: $prebuilt_path" >&2
            exit 0
          fi

          applied_file="$state_dir/appearance-variant"
          if [ -f "$applied_file" ] && [ "$(tr -d '[:space:]' < "$applied_file")" = "$desired" ]; then
            exit 0
          fi

          : > "$state_dir/fast-activate"
          if "$prebuilt_path/activate"; then
            printf '%s\n' "$desired" > "$applied_file"
            /bin/sh /etc/dendritic-appearance-reload-hooks.sh >/dev/null 2>&1 || true
          fi
          rm -f "$state_dir/fast-activate"
        '';

        environment.etc."dendritic-appearance-detect.sh".text = ''
          #!/bin/sh
          exec ${lib.getExe appearancePkg} detect
        '';
      };
    };

  # Linux: ensure package on PATH when wallpaper enabled (HM already adds it).
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      appearancePkg = pkgs.rustPlatform.buildRustPackage {
        pname = "dendritic-appearance";
        version = "0.1.0";
        src = ./dendritic-appearance;
        cargoLock.lockFile = ./dendritic-appearance/Cargo.lock;
        meta.mainProgram = "dendritic-appearance";
      };
    in
    {
      config = lib.mkIf (config.dendritic.apps.niri.enable or false) {
        environment.systemPackages = [ appearancePkg ];
      };
    };
}
