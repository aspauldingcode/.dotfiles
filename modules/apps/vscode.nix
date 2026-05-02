{
  flake.modules.homeManager.vscode = { pkgs, lib, config, ... }: {
    options.dendritic.apps.vscode = {
      enable = lib.mkEnableOption "VS Code / Cursor IDE";
    };

    imports = [ ./_vscode-common.nix ];
    config = lib.mkIf config.dendritic.apps.vscode.enable {
      programs.vscode = {
        package = if pkgs.stdenv.isDarwin then pkgs.vscode else pkgs.vscode-fhs;
      };

      # Ensure extensions are linked
      home.file.".cursor/extensions/bbenoist.Nix".source = 
        "${pkgs.vscode-extensions.bbenoist.nix}/share/vscode/extensions/bbenoist.Nix";
      home.file.".cursor/extensions/jnoortheen.nix-ide".source = 
        "${pkgs.vscode-extensions.jnoortheen.nix-ide}/share/vscode/extensions/jnoortheen.nix-ide";

      home.packages = [ config.programs.vscode.package ];
    };
  };
}
