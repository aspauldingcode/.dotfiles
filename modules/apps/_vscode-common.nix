{ pkgs, lib, ... }: 
let
  modern-pdf-preview = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    publisher = "chocolatedesue";
    name = "modern-pdf-preview";
    version = "1.5.9";
    sha256 = "0qwzwaynf7wb7lfaaimxlr0n1ngrc68q15mv6hdjpffp52yq7rbh";
  };
in
{
  # ── Shared settings & extensions for VSCode, Cursor, and Antigravity ──
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "cursor.composer.enabled" = false;
      "files.readonlyFromPermissions" = true;
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = lib.mkForce "Stylix";
      "editor.fontFamily" = lib.mkForce "'Maple Mono NF', monospace";
      "editor.fontSize" = lib.mkForce 12;
      "editor.fontLigatures" = "'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'cv01', 'cv02', 'cv03'";
      "editor.rulers" = [ 80 ];
      "terminal.integrated.fontFamily" = "'Maple Mono NF'";
      "terminal.integrated.fontSize" = lib.mkForce 12;
      "window.zoomLevel" = 0;
      "swiftformat.path" = "${pkgs.swiftformat}/bin/swiftformat";
      "workbench.editorAssociations" = {
        "*.pdf" = "chocolatedesue.modern-pdf-preview";
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";
      "nix.serverSettings" = {
        "nil" = {
          "formatting" = {
            "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
          };
        };
      };
      "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
      "[swift]" = {
        "editor.defaultFormatter" = "nicklockwood.swiftformat";
        "editor.formatOnSave" = true;
      };
      "[asm]" = {
        "editor.formatOnSave" = true;
      };
      "[s]" = {
        "editor.formatOnSave" = true;
      };
      "[java]" = {
        "editor.defaultFormatter" = "redhat.java";
        "editor.formatOnSave" = true;
      };
      "java.format.settings.url" = "${./eclipse-java-google-style.xml}";
      "java.format.settings.profile" = "GoogleStyle";
      "java.format.enabled" = true;
      "tinymist.preview.refresh" = "onType";
      "[typst]" = {
        "editor.defaultFormatter" = "myriad-dreamin.tinymist";
        "editor.formatOnSave" = true;
      };
      "C_cpp.intelliSenseEngine" = "disabled";
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
      ms-vscode.cpptools
      modern-pdf-preview
      myriad-dreamin.tinymist
    ];
  };
}
