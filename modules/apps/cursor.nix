{
  flake.modules.homeManager.cursor = { pkgs, lib, config, ... }: let
    cfg = config.dendritic.apps.cursor;

    # ── Derive settings & extensions from Antigravity (1:1) ──────
    # Antigravity uses programs.vscode, which Stylix auto-themes.
    # Cursor reuses the exact same resolved settings + extensions
    # so both editors are always visually identical.
    sharedSettings = config.programs.vscode.profiles.default.userSettings;
    sharedExtensions = config.programs.vscode.profiles.default.extensions;

    # Build extension symlinks by reading each extension's directory
    extensionFiles = lib.foldl' (acc: ext: let
      extPath = "${ext}/share/vscode/extensions";
      dirs = builtins.attrNames (builtins.readDir extPath);
    in acc // (lib.listToAttrs (map (dir: {
      name = ".cursor/extensions/${dir}";
      value = { source = "${extPath}/${dir}"; };
    }) dirs))) {} sharedExtensions;
  in {
    imports = [ ./_vscode-common.nix ];
    options.dendritic.apps.cursor = {
      enable = lib.mkEnableOption "Cursor IDE";
    };

    config = lib.mkIf cfg.enable {
      home.packages = [
        (if pkgs.stdenv.isLinux then pkgs.code-cursor-fhs else pkgs.code-cursor)
      ];

      # Link derived extensions (symlinks)
      home.file = extensionFiles // lib.optionalAttrs pkgs.stdenv.isDarwin {
        "Library/Application Support/Cursor/User/settings.json" = {
          force = true;
          text = builtins.toJSON sharedSettings;
        };
      } // lib.optionalAttrs pkgs.stdenv.isLinux {
        ".cursor/User/settings.json".text = builtins.toJSON sharedSettings;
      };
    };
  };

  # Dock registration: Cursor owns its dock entry
  flake.modules.darwin.cursor = { pkgs, ... }: {
    dendritic.dock.apps = [
      "${if pkgs.stdenv.isDarwin then pkgs.code-cursor else pkgs.code-cursor-fhs}/Applications/Cursor.app"
    ];
  };
}
