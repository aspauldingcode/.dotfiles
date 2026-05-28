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
            name = ".antigravity/extensions/${dir}";
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

      imports = [ ./_vscode-common.nix ];
      config = lib.mkIf cfg.enable {
        home.packages = [
          (if pkgs.stdenv.isDarwin then pkgs.antigravity else pkgs.antigravity-fhs)
        ];

        # Mirror VS Code settings/extensions so Stylix + editor defaults stay in sync.
        home.file =
          extensionFiles
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            "Library/Application Support/Antigravity/User/settings.json" = {
              force = true;
              text = builtins.toJSON sharedSettings;
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            ".antigravity/User/settings.json".text = builtins.toJSON sharedSettings;
            ".config/Antigravity/User/settings.json".text = builtins.toJSON sharedSettings;
          };
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
    in
    lib.mkIf antigravityEnabled {
      dendritic.dock.apps = lib.mkOrder 170 [
        "${
          if pkgs.stdenv.isDarwin then pkgs.antigravity else pkgs.antigravity-fhs
        }/Applications/Antigravity.app"
      ];
    };
}
