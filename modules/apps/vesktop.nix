{
  # Vesktop: Discord stays native. TintedBrowse LUT rewriter (Chrome
  # extension loaded into Electron) walks authored CSS colors through
  # OKLab Gaussian RBF. QuickCSS only exposes --tb-baseXX tokens.

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      tintedInject = pkgs.callPackage ./tinted-inject { };
      vesktopPkg = import ./tinted-inject/_wrap-vesktop.nix {
        inherit pkgs tintedInject;
      };
      c = config.lib.stylix.colors;
      # Auxiliary palette sheet only (TintedBrowse `buildThemeCss`). Not a
      # Discord chrome remap — appearance overwrites this from colors.toml.
      paletteCss = ''
        :root, :host {
          --tb-base00: #${c.base00};
          --tb-base01: #${c.base01};
          --tb-base02: #${c.base02};
          --tb-base03: #${c.base03};
          --tb-base04: #${c.base04};
          --tb-base05: #${c.base05};
          --tb-base06: #${c.base06};
          --tb-base07: #${c.base07};
          --tb-base08: #${c.base08};
          --tb-base09: #${c.base09};
          --tb-base0A: #${c.base0A};
          --tb-base0B: #${c.base0B};
          --tb-base0C: #${c.base0C};
          --tb-base0D: #${c.base0D};
          --tb-base0E: #${c.base0E};
          --tb-base0F: #${c.base0F};
        }
      '';
    in
    {
      config = {
        stylix.targets.vesktop.enable = lib.mkForce false;

        home.activation.signVesktopApp = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            _app="$HOME/Applications/Home Manager Apps/Vesktop.app"
            if [ ! -e "$_app" ]; then
              :
            elif [ -L "$_app" ]; then
              _target="$(${pkgs.coreutils}/bin/readlink "$_app")"
              case "$_target" in
                /nix/store/*) ;;
                *)
                  /usr/bin/codesign --force --sign - "$_target"
                  ;;
              esac
            elif [ -d "$_app" ]; then
              /usr/bin/codesign --force --sign - "$_app"
            fi
          ''
        );

        home.activation.vesktopClearManagedCss = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          cfg="${
            if pkgs.stdenv.isDarwin then
              "${config.home.homeDirectory}/Library/Application Support/vesktop"
            else
              "${config.xdg.configHome}/vesktop"
          }"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f \
            "$cfg/settings.json.backup" \
            "$cfg/settings/settings.json.backup" \
            "$cfg/settings/quickCss.css" \
            "$cfg/settings/quickCss.css.backup" \
            "$cfg/themes/stylix.css" \
            "$cfg/themes/stylix.css.backup" \
            "$cfg/themes/dendritic-overrides.css" \
            "$cfg/themes/dendritic-overrides.css.backup" || true
        '';

        home.activation.vesktopMaterializeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          cfg="${
            if pkgs.stdenv.isDarwin then
              "${config.home.homeDirectory}/Library/Application Support/vesktop"
            else
              "${config.xdg.configHome}/vesktop"
          }"
          $DRY_RUN_CMD mkdir -p "$cfg/settings" "$cfg/themes"
          for f in \
            "$cfg/settings.json" \
            "$cfg/settings/settings.json" \
            "$cfg/settings/quickCss.css"
          do
            if [ -L "$f" ]; then
              target="$(${pkgs.coreutils}/bin/readlink -f "$f")"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$f"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f "$target" "$f"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod u+w "$f"
            fi
          done
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f \
            "$cfg/themes/stylix.css" \
            "$cfg/themes/dendritic-overrides.css" || true
        '';

        programs.vesktop = {
          enable = true;
          package = lib.mkForce vesktopPkg;

          settings = {
            arRPC = true;
            checkUpdates = false;
            hardwareAcceleration = true;
            minimizeToTray = false;
            tray = false;
            splashTheming = true;
            staticTitle = true;
            discordBranch = "stable";
            splashBackground = "#${c.base00}";
            splashColor = "#${c.base0D}; --fg-semi-trans: transparent";
          };

          vencord.settings = {
            autoUpdate = false;
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
            useQuickCss = true;
            enabledThemes = lib.mkForce [ ];

            plugins = {
              MessageLogger = {
                enabled = true;
                ignoreSelf = true;
              };
              NoDevtoolsWarning.enabled = true;
              SilentTyping.enabled = true;
              FakeNitro.enabled = true;
            };
          };

          vencord.extraQuickCss = lib.mkForce paletteCss;
        };
      };
    };

  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    let
      tintedInject = pkgs.callPackage ./tinted-inject { };
      vesktopPkg = import ./tinted-inject/_wrap-vesktop.nix {
        inherit pkgs tintedInject;
      };
    in
    {
      dendritic.dock.apps = lib.mkOrder 130 [
        "${vesktopPkg}/Applications/Vesktop.app"
      ];
    };
}
