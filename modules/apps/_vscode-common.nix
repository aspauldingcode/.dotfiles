{
  pkgs,
  lib,
  config,
  ...
}:
let
  fontName = config.stylix.fonts.monospace.name;
  appFontSize = config.stylix.fonts.sizes.applications;

  modern-pdf-preview = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    publisher = "chocolatedesue";
    name = "modern-pdf-preview";
    version = "1.5.9";
    sha256 = "0qwzwaynf7wb7lfaaimxlr0n1ngrc68q15mv6hdjpffp52yq7rbh";
  };

  # treefmt VSCode: unifies all formatters behind one `treefmt` call.
  # https://marketplace.visualstudio.com/items?itemName=ibecker.treefmt-vscode
  treefmt-vscode = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    publisher = "ibecker";
    name = "treefmt-vscode";
    version = "2.4.1";
    sha256 = "sha256-ZTRrZDXqK9L7E5fr5NLEa/0ZyTnFdItfytbVuh/qr94=";
  };

  # Google's official Eclipse-JDT formatter profile, fetched at build time
  # from `google/styleguide` and pinned to an immutable commit so the
  # `redhat.java` extension's "Format Document" always lands on the exact
  # same byte-for-byte settings file. Pulling from upstream keeps the asset
  # out of this repo's tree (it used to live as a 338-line XML next to
  # this module, which the dendritic layout reserves for Nix modules
  # only). To bump the profile, refresh both `rev` and `hash`:
  #
  #   curl -fsSL https://api.github.com/repos/google/styleguide/commits/gh-pages \
  #     | jq -r .sha                                  # → new rev
  #   nix store prefetch-file --hash-type sha256 --json \
  #     "https://raw.githubusercontent.com/google/styleguide/<rev>/eclipse-java-google-style.xml" \
  #     | jq -r .hash                                 # → new hash (SRI)
  eclipse-java-google-style = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/google/styleguide/3c5c895c68bfb108cd5d936937dc36e2dfbdbcc2/eclipse-java-google-style.xml";
    hash = "sha256-51Uku2fj/8iNXGgO11JU4HLj28y7kcSgxwjc+r8r35E=";
  };
in
{
  # ── Shared settings & extensions for VSCode, Cursor, and Antigravity ──
  programs.vscode = {
    enable = true;
    # Avoid Home Manager's onChange hook that shells out to `code --list-extensions`
    # during activation; recent Electron/Node builds can crash in headless mode.
    mutableExtensionsDir = false;
    profiles.default.userSettings = {
      "cursor.composer.enabled" = false;
      "cursor.composer.shouldChimeAfterChatFinishes" = true;
      "files.readonlyFromPermissions" = true;
      "window.titleBarStyle" = "custom";
      "window.autoDetectColorScheme" = true;
      "window.autoDetectHighContrast" = true;
      "workbench.colorTheme" = lib.mkForce "Stylix";
      "workbench.preferredDarkColorTheme" = lib.mkForce "Stylix";
      "workbench.preferredLightColorTheme" = lib.mkForce "Stylix";
      "workbench.colorCustomizations" = {
        "titleBar.activeBackground" = "#${config.lib.stylix.colors.base00}";
        "titleBar.inactiveBackground" = "#${config.lib.stylix.colors.base00}";
        "titleBar.activeForeground" = "#${config.lib.stylix.colors.base05}";
        "titleBar.inactiveForeground" = "#${config.lib.stylix.colors.base04}";
      };
      "editor.fontFamily" = lib.mkForce "'${fontName}', monospace";
      "editor.fontSize" = lib.mkForce appFontSize;
      "editor.fontLigatures" = "'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'cv01', 'cv02', 'cv03'";
      "editor.rulers" = [ 80 ];
      "terminal.integrated.fontFamily" = "'${fontName}'";
      "terminal.integrated.fontSize" = lib.mkForce appFontSize;
      "window.zoomLevel" = 0;

      # ── Workspace trust: disabled (Nix manages everything) ───────
      "security.workspace.trust.enabled" = false;
      # Fork-specific toggle used by Cursor/Antigravity builds.
      "workspaceValidation" = false;
      "workspaceValidation.enabled" = false;

      # ── treefmt: global default formatter ────────────────────────
      "treefmt.path" = "${pkgs.treefmt}/bin/treefmt";
      "editor.defaultFormatter" = "ibecker.treefmt-vscode";
      "editor.formatOnSave" = true;

      # ── Per-language overrides that treefmt doesn't cover ────────
      # Keep typst (tinymist) and java (redhat.java) as explicit formatters.
      "[typst]" = {
        "editor.defaultFormatter" = "myriad-dreamin.tinymist";
        "editor.formatOnSave" = true;
      };
      "[java]" = {
        "editor.defaultFormatter" = "redhat.java";
        "editor.formatOnSave" = true;
      };
      "java.format.settings.url" = "${eclipse-java-google-style}";
      "java.format.settings.profile" = "GoogleStyle";
      "java.format.enabled" = true;

      # ── workbench ─────────────────────────────────────────────────
      "workbench.editorAssociations" = {
        "*.pdf" = "chocolatedesue.modern-pdf-preview";
      };
      "tinymist.preview.refresh" = "onType";

      # ── Clangd / C++ ─────────────────────────────────────────────
      "C_cpp.intelliSenseEngine" = "disabled";
    };

    profiles.default.extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      # jnoortheen.nix-ide excluded — treefmt handles nix formatting
      # Keep Python base + debugger stack explicit so Ruff, Cursor Pyright,
      # and Python Debugger dependencies resolve in every VS Code fork.
      ms-python.python
      ms-python.debugpy
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
      treefmt-vscode
    ];
  };

  # Force-remove extensions that must not be installed in any VSCode fork.
  # This runs after the extension dirs are unlocked and before they are relocked,
  # so a deleted extension cannot survive the activation cycle.
  home.activation.purgeBlockedVscodeExtensions =
    lib.hm.dag.entryBetween [ "lockManagedVscodeExtensionDirs" ] [ "unlockManagedVscodeExtensionDirs" ]
      ''
        for EXT_DIR in \
          "$HOME/.vscode/extensions" \
          "$HOME/.cursor/extensions" \
          "$HOME/.antigravity/extensions"
        do
          # Remove jnoortheen.nix-ide — conflicts with bbenoist.nix (already managed).
          for MATCH in "$EXT_DIR"/jnoortheen.nix-ide-*; do
            [ -e "$MATCH" ] && rm -rf "$MATCH" || true
          done
        done
      '';

  # Keep nix-managed extension directories immutable in all VSCode forks.
  # Unlock before HM link checks so generation updates can apply, then
  # relock after links are materialized so in-app uninstall/remove fails.
  home.activation.unlockManagedVscodeExtensionDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    MANAGED_EXTENSION_DIRS="
      $HOME/.vscode/extensions
      $HOME/.cursor/extensions
      $HOME/.antigravity/extensions
    "

    for EXT_DIR in $MANAGED_EXTENSION_DIRS; do
      if [ -e "$EXT_DIR" ]; then
        chmod u+rwx "$EXT_DIR" || true
      fi
    done
  '';

  home.activation.lockManagedVscodeExtensionDirs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    MANAGED_EXTENSION_DIRS="
      $HOME/.vscode/extensions
      $HOME/.cursor/extensions
      $HOME/.antigravity/extensions
    "

    for EXT_DIR in $MANAGED_EXTENSION_DIRS; do
      if [ -d "$EXT_DIR" ]; then
        chmod a-w "$EXT_DIR" || true
      fi
    done
  '';
}
