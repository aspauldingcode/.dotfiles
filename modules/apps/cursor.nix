{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.cursor;

      # ── Derive settings & extensions from Antigravity (1:1) ──────
      # Antigravity uses programs.vscode, which Stylix auto-themes.
      # Cursor reuses the exact same resolved settings + extensions
      # so both editors are always visually identical.
      sharedSettings = config.programs.vscode.profiles.default.userSettings;
      sharedExtensions = config.programs.vscode.profiles.default.extensions;

      # Build extension symlinks by reading each extension's directory
      extensionFiles = lib.foldl' (
        acc: ext:
        let
          extPath = "${ext}/share/vscode/extensions";
          dirs = builtins.attrNames (builtins.readDir extPath);
        in
        acc
        // (lib.listToAttrs (
          map (dir: {
            name = ".cursor/extensions/${dir}";
            value = {
              source = "${extPath}/${dir}";
            };
          }) dirs
        ))
      ) { } sharedExtensions;
    in
    {
      imports = [
        ./_vscode-common.nix
        ./_ide-mcp.nix
      ];
      options.dendritic.apps.cursor = {
        enable = lib.mkEnableOption "Cursor IDE";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          (if pkgs.stdenv.isLinux then pkgs.code-cursor-fhs else pkgs.code-cursor)
        ];

        # Link derived extensions (symlinks)
        home.file =
          extensionFiles
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            "Library/Application Support/Cursor/User/settings.json" = {
              force = true;
              text = builtins.toJSON sharedSettings;
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            # On Linux, Cursor reads user settings from the XDG config dir
            # (~/.config/Cursor/User), NOT ~/.cursor/User. Writing only the
            # latter left the real settings file (with the Stylix colorTheme)
            # unmanaged, so Stylix never applied. Write both paths — the XDG
            # one is authoritative and needs `force` since Cursor may have
            # already created a plain settings.json there.
            ".config/Cursor/User/settings.json" = {
              force = true;
              text = builtins.toJSON sharedSettings;
            };
            ".cursor/User/settings.json".text = builtins.toJSON sharedSettings;
          };
      };
    };

  # Dock registration: Cursor owns its dock entry (order 160 in `dock.nix`).
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      cursorEnabled = config.home-manager.users.${user}.dendritic.apps.cursor.enable or false;
    in
    lib.mkIf cursorEnabled {
      dendritic.dock.apps = lib.mkOrder 160 [
        "${if pkgs.stdenv.isDarwin then pkgs.code-cursor else pkgs.code-cursor-fhs}/Applications/Cursor.app"
      ];
    };
}
