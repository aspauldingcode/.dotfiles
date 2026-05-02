{ pkgs, lib, ... }: {
  # ── Shared settings & extensions for VSCode, Cursor, and Antigravity ──
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "cursor.composer.enabled" = false;
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = lib.mkForce "Stylix";
      "editor.fontSize" = lib.mkForce 12;
      "editor.fontLigatures" = true;
      "editor.rulers" = [ 80 ];
      "terminal.integrated.fontSize" = lib.mkForce 12;
      "window.zoomLevel" = 0;
      "swiftformat.path" = "${pkgs.swiftformat}/bin/swiftformat";
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
    ];
  };
}
