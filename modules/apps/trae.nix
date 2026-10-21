{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.trae;
      traePkg = pkgs.callPackage ../pkgs/_trae.nix { };
      sharedSettings = config.programs.vscode.profiles.default.userSettings;
      sharedExtensions = config.programs.vscode.profiles.default.extensions;

      # product.json dataFolderName = `.trae`.
      extensionFiles = lib.foldl' (
        acc: ext:
        let
          extPath = "${ext}/share/vscode/extensions";
          dirs = builtins.attrNames (builtins.readDir extPath);
        in
        acc
        // (lib.listToAttrs (
          map (dir: {
            name = ".trae/extensions/${dir}";
            value.source = "${extPath}/${dir}";
          }) dirs
        ))
      ) { } sharedExtensions;
    in
    {
      options.dendritic.apps.trae = {
        enable = lib.mkEnableOption "Trae IDE (Linux .deb, FHS-wrapped)";
      };

      imports = [ ./_vscode-common.nix ];

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
        home.packages = [
          traePkg
          # Upstream ships only a 1024² pixmap; fuzzel needs hicolor sizes.
          (pkgs.runCommand "trae-hicolor-icons" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
            for sz in 16 24 32 48 64 128 256 512; do
              mkdir -p "$out/share/icons/hicolor/''${sz}x''${sz}/apps"
              magick ${traePkg.unwrapped}/share/pixmaps/trae.png -resize "''${sz}x''${sz}" \
                "$out/share/icons/hicolor/''${sz}x''${sz}/apps/trae.png"
            done
          '')
        ];

        home.file = extensionFiles // {
          ".config/Trae/User/settings.json".text = builtins.toJSON sharedSettings;
        };
      };
    };
}
