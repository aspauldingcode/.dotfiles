{
  flake.modules.homeManager.antigravity = { pkgs, lib, config, ... }: {
    options.dendritic.apps.antigravity = {
      enable = lib.mkEnableOption "Antigravity IDE";
    };

    imports = [ ./_vscode-common.nix ];
    config = lib.mkIf config.dendritic.apps.antigravity.enable {
      home.packages = [
        (if pkgs.stdenv.isDarwin then pkgs.antigravity else pkgs.antigravity-fhs)
      ];

      # Ensure extensions are linked for Antigravity
      home.file.".antigravity/extensions/bbenoist.Nix".source = 
        "${pkgs.vscode-extensions.bbenoist.nix}/share/vscode/extensions/bbenoist.Nix";
      home.file.".antigravity/extensions/jnoortheen.nix-ide".source = 
        "${pkgs.vscode-extensions.jnoortheen.nix-ide}/share/vscode/extensions/jnoortheen.nix-ide";
    };
  };
}
