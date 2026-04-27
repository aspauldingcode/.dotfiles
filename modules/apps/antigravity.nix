{
  flake.modules.homeManager.antigravity = { pkgs, lib, config, ... }: {
    options.dendritic.apps.antigravity = {
      enable = lib.mkEnableOption "Antigravity IDE";
    };

    config = lib.mkIf config.dendritic.apps.antigravity.enable {
      programs.vscode = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then pkgs.antigravity else pkgs.antigravity-fhs;
        
        profiles.default.userSettings = {
          "window.titleBarStyle" = "custom";
          "workbench.colorTheme" = lib.mkForce "Stylix";
          "editor.fontSize" = lib.mkForce 12;
          "editor.fontLigatures" = true;
          "terminal.integrated.fontSize" = lib.mkForce 12;
          "window.zoomLevel" = 0;
          "swiftformat.path" = "${pkgs.swiftformat}/bin/swiftformat";
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
            "editor.formatOnSave" = true;
          };
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
          "[swift]" = {
            "editor.defaultFormatter" = "nicklockwood.swiftformat";
            "editor.formatOnSave" = true;
          };
        };

        profiles.default.extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          jnoortheen.nix-ide
          ms-python.python
          charliermarsh.ruff
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          rust-lang.rust-analyzer
          llvm-vs-code-extensions.vscode-clangd
          redhat.java
          sumneko.lua
          tamasfe.even-better-toml
          ms-vscode-remote.remote-ssh
        ];
      };

      # Ensure extensions are linked for Antigravity
      home.file.".antigravity/extensions/bbenoist.Nix".source = 
        "${pkgs.vscode-extensions.bbenoist.nix}/share/vscode/extensions/bbenoist.Nix";
      home.file.".antigravity/extensions/jnoortheen.nix-ide".source = 
        "${pkgs.vscode-extensions.jnoortheen.nix-ide}/share/vscode/extensions/jnoortheen.nix-ide";

      home.packages = [ config.programs.vscode.package ];
    };
  };
}
