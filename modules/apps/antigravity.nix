{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.antigravity;
      sharedSettings = config.programs.vscode.profiles.default.userSettings;
      sharedExtensions = config.programs.vscode.profiles.default.extensions;

      # nixpkgs renamed antigravity → antigravity-ide (2.x). dataFolderName is
      # `.antigravity-ide`; the Darwin bundle is `Antigravity IDE.app`.
      antigravityPkg =
        if pkgs.stdenv.isDarwin then
          (pkgs.antigravity-ide or pkgs.antigravity)
        else
          (pkgs.antigravity-ide-fhs or pkgs.antigravity-fhs);

      enableAgentSoundsScript = pkgs.writeText "antigravity-enable-agent-sounds.py" (
        builtins.readFile ../../scripts/antigravity-enable-agent-sounds.py
      );

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
            name = ".antigravity-ide/extensions/${dir}";
            value = {
              source = "${extPath}/${dir}";
            };
          }) dirs
        ))
      ) { } sharedExtensions;
    in
    {
      options.dendritic.apps.antigravity = {
        enable = lib.mkEnableOption "Antigravity IDE";
      };

      imports = [
        ./_vscode-common.nix
        ./_ide-mcp.nix
      ];
      config = lib.mkIf cfg.enable {
        home.packages = [
          antigravityPkg
          (pkgs.writeShellScriptBin "antigravity" ''
            exec ${lib.getExe antigravityPkg} "$@"
          '')
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          # Same as Cursor: nixpkgs only ships 1024² into hicolor, which fuzzel
          # skips (no 1024x1024/apps in hicolor's index.theme).
          (pkgs.runCommand "antigravity-hicolor-icons" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
            src=
            for cand in \
              ${antigravityPkg}/share/pixmaps/antigravity-ide.png \
              ${antigravityPkg}/share/pixmaps/antigravity.png; do
              if [ -f "$cand" ]; then src="$cand"; break; fi
            done
            test -n "$src"
            for sz in 16 24 32 48 64 128 256 512; do
              mkdir -p "$out/share/icons/hicolor/''${sz}x''${sz}/apps"
              magick "$src" -resize "''${sz}x''${sz}" \
                "$out/share/icons/hicolor/''${sz}x''${sz}/apps/antigravity-ide.png"
              cp "$out/share/icons/hicolor/''${sz}x''${sz}/apps/antigravity-ide.png" \
                "$out/share/icons/hicolor/''${sz}x''${sz}/apps/antigravity.png"
            done
          '')
        ];

        # Mirror VS Code settings/extensions so Stylix + editor defaults stay in sync.
        home.file =
          extensionFiles
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            "Library/Application Support/Antigravity IDE/User/settings.json" = {
              force = true;
              text = builtins.toJSON sharedSettings;
            };
            # Pre-rename 1.x profile path (wallpaper/appearance still patch both).
            "Library/Application Support/Antigravity/User/settings.json" = {
              force = true;
              text = builtins.toJSON sharedSettings;
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            ".antigravity-ide/User/settings.json".text = builtins.toJSON sharedSettings;
            ".config/Antigravity IDE/User/settings.json".text = builtins.toJSON sharedSettings;
            ".config/Antigravity/User/settings.json".text = builtins.toJSON sharedSettings;
          };

        # Antigravity stores agent completion sounds in USS agent preferences
        # (state.vscdb), not settings.json. Patch the sentinel on activation.
        home.activation.antigravityEnableAgentCompletionSound = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.python3}/bin/python3 ${enableAgentSoundsScript}
        '';
      };
    };

  # Dock registration: Antigravity owns its dock entry (order 170 in `dock.nix`).
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      antigravityEnabled = config.home-manager.users.${user}.dendritic.apps.antigravity.enable or false;
      antigravityPkg = pkgs.antigravity-ide or pkgs.antigravity;
      darwinAppName =
        let
          apps = builtins.attrNames (builtins.readDir "${antigravityPkg}/Applications");
        in
        lib.findFirst (n: lib.hasSuffix ".app" n) "Antigravity IDE.app" apps;
    in
    lib.mkIf antigravityEnabled {
      dendritic.dock.apps = lib.mkOrder 170 [
        "${antigravityPkg}/Applications/${darwinAppName}"
      ];
    };
}
