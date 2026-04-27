# ── Mac App Store (mas) Module ─────────────────────────────────
#
# Provides declarative Nix options for managing Mac App Store
# installations via the `mas` CLI. This module is darwin-only and
# is designed to be separable as a standalone flake module.
#
# Usage (in host config):
#   dendritic.mas.enable = true;
#   dendritic.mas.apps = {
#     Xcode = 497799835;
#   };
#   dendritic.mas.safari.extensions = [
#     { name = "uBlock Origin Lite"; id = 6745342698; }
#   ];
#
# Prerequisites:
#   - You MUST be signed into the Mac App Store GUI manually.
#     `mas signin` is disabled on macOS 10.13+.
#   - Some apps (like Xcode) require additional Apple ID auth.
#
{
  # ── Darwin System Module ───────────────────────────────────────
  # This runs at the nix-darwin level (system activation).
  flake.modules.darwin.mas = { pkgs, lib, config, ... }:
  let
    cfg = config.dendritic.mas;

    # Build the complete list of app IDs to install:
    # 1. Named apps from the attrset (e.g. { Xcode = 497799835; })
    # 2. Safari extensions from the list
    allApps = cfg.apps // (builtins.listToAttrs (map (ext: {
      name = ext.name;
      value = ext.id;
    }) cfg.safari.extensions));

    masPackage = pkgs.mas;
  in
  {
    # ── Options ─────────────────────────────────────────────────
    options.dendritic.mas = {
      enable = lib.mkEnableOption "Mac App Store management via mas CLI";

      apps = lib.mkOption {
        type = lib.types.attrsOf lib.types.int;
        default = {};
        example = lib.literalExpression ''
          {
            Xcode = 497799835;
            "1Password for Safari" = 1569813296;
          }
        '';
        description = ''
          Attribute set of Mac App Store applications to install.
          Keys are human-readable names (for logging), values are
          the numeric App Store IDs.

          Find IDs with: `mas search <app name>`
        '';
      };

      safari.extensions = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable name of the Safari extension.";
              example = "uBlock Origin Lite";
            };
            id = lib.mkOption {
              type = lib.types.int;
              description = "Mac App Store ID of the Safari extension.";
              example = 6745342698;
            };
          };
        });
        default = [];
        example = lib.literalExpression ''
          [
            { name = "uBlock Origin Lite"; id = 6745342698; }
            { name = "1Password for Safari"; id = 1569813296; }
          ]
        '';
        description = ''
          List of Safari extensions to install from the Mac App Store.
          Each entry has a `name` (for display/logging) and an `id`
          (the numeric App Store ID).

          These are installed via `mas install` just like regular apps,
          but are separated for semantic clarity — matching the pattern
          used by `programs.brave.extensions` and Firefox's
          `ExtensionSettings`.

          After installation, extensions must be enabled in:
            Safari → Settings → Extensions
        '';
      };

      safari.enableExtensionsOnInstall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Attempt to enable Safari extensions automatically after
          installation. This uses `pluginkit` and may require
          additional permissions. Disabled by default since Safari
          extensions typically need manual consent.
        '';
      };
    };

    # ── Implementation ──────────────────────────────────────────
    config = lib.mkIf cfg.enable {
      # Ensure mas + the sync wrapper are available system-wide.
      # The sync script is called AFTER `nh darwin switch` by the
      # install script so the user sees full interactive output.
      environment.systemPackages = [
        masPackage
        (pkgs.writeShellScriptBin "mas-sync" ''
          set -euo pipefail
          export PATH="${lib.makeBinPath [ masPackage pkgs.coreutils ]}:$PATH"
          export MAS_NO_AUTO_INDEX=1

          echo ""
          echo "══════════════════════════════════════════════════════════"
          echo "  Mac App Store — Declarative Sync via mas"
          echo "══════════════════════════════════════════════════════════"
          echo ""
          echo "  ℹ  You must be signed into the Mac App Store GUI."
          echo "     (mas signin is disabled on modern macOS)"
          echo ""

          INSTALLED=$(mas list 2>/dev/null || true)

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
            if echo "$INSTALLED" | grep -q "^${toString id} "; then
              echo "  ✓ ${name} (${toString id}) — already installed"
            else
              echo "  ⤓ Installing ${name} (${toString id})..."
              # Use 'purchase' for first-time free downloads,
              # fall back to 'install' for previously purchased apps.
              if mas purchase ${toString id}; then
                echo "  ✓ ${name} — installed successfully"
              elif mas install ${toString id}; then
                echo "  ✓ ${name} — re-installed successfully"
              else
                echo "  ✗ ${name} — install failed (check App Store sign-in)" >&2
              fi
            fi
          '') allApps)}

          echo ""
          echo "══════════════════════════════════════════════════════════"
          echo "  Mac App Store sync complete."
          echo "══════════════════════════════════════════════════════════"
        '')
      ];
    };
  };
}
