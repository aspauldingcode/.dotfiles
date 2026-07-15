{
  # ── Vesktop (Discord replacement) ─────────────────────────────
  # Replaces vanilla Discord entirely with Vesktop (Vencord-powered client).
  # Stylix auto-generates a base16 CSS theme and injects it via Vencord's
  # theme loader using `stylix.targets.vesktop`.
  #
  # Stylix wiring (discord/vesktop.nix target):
  #   stylix.targets.vesktop.enable = true
  #   → programs.vesktop.vencord.themes.stylix = <generated-css>
  #   → programs.vesktop.vencord.settings.enabledThemes = [ "stylix.css" ]
  #
  # Vesktop is supported on both Linux and Darwin (macOS).
  # Reference: https://github.com/nix-community/stylix/blob/master/modules/discord/vesktop.nix

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      inputs,
      config,
      ...
    }:
    {
      config = {
        # ── Stylix: enable the vesktop colourscheme target ───────────
        stylix.targets.vesktop.enable = true;

        # Adhoc-sign Vesktop when it is a writable local bundle. Store
        # symlinks are already signed at build time; `--deep` fails on them.
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

        # ── Vesktop application ──────────────────────────────────────
        programs.vesktop = {
          enable = pkgs.stdenv.isDarwin;
          package = lib.mkIf pkgs.stdenv.isDarwin (lib.mkForce pkgs.vesktop);

          # Application-level settings
          # Written to $XDG_CONFIG_HOME/vesktop/settings.json
          settings = {
            arRPC = true; # Rich Presence via arRPC
            checkUpdates = false; # Nix manages the package version
            hardwareAcceleration = true;
            minimizeToTray = false;
            tray = false;
            splashTheming = true; # Stylix themes the splash screen too
            staticTitle = true;
            discordBranch = "stable";
            # Stylix: inject palette colors into the splash/loading panel.
            # Vesktop's splash .wrapper uses `border: 1px solid var(--fg-semi-trans)`.
            # Hex splashColor skips the rgb→rgba conversion, so that border becomes a
            # solid accent outline. Append a CSS override so the border is invisible.
            splashBackground = "#${config.lib.stylix.colors.base00}";
            splashColor = "#${config.lib.stylix.colors.base0D}; --fg-semi-trans: transparent";
          };

          # Vencord plugin / theme settings
          # Written to $XDG_CONFIG_HOME/vesktop/settings/settings.json
          vencord.settings = {
            autoUpdate = false; # Nix pins the Vencord version
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
            useQuickCss = true; # Needed to load extraQuickCss below
            enabledThemes = lib.mkForce [
              "stylix.css"
              "dendritic-overrides.css"
            ];

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

          # Force a stable surface/text/button contract on top of Stylix:
          # - Sidebar: base01
          # - Titlebar: base00
          # - Main chat/content:  base00
          # - Full text + controls mapped to base16 tokens
          # Do not include ".css" in the key: HM appends it to the filename.
          # If we include it here, the generated file becomes *.css.css and
          # Vesktop won't load it from enabledThemes.
          vencord.themes."dendritic-overrides" = ''
            :root,
            .theme-dark,
            .theme-light,
            .theme-darker,
            .theme-midnight,
            .visual-refresh {
              --base00: #${config.lib.stylix.colors.base00};
              --base01: #${config.lib.stylix.colors.base01};
              --base02: #${config.lib.stylix.colors.base02};
              --base03: #${config.lib.stylix.colors.base03};
              --base04: #${config.lib.stylix.colors.base04};
              --base05: #${config.lib.stylix.colors.base05};
              --base06: #${config.lib.stylix.colors.base06};
              --base07: #${config.lib.stylix.colors.base07};
              --base08: #${config.lib.stylix.colors.base08};
              --base0D: #${config.lib.stylix.colors.base0D};

              --font-primary: "Inter", "Maple Mono NF", "SF Pro Text", "Helvetica Neue", sans-serif !important;
              --font-display: "Inter", "Maple Mono NF", "SF Pro Text", "Helvetica Neue", sans-serif !important;
              --font-headline: "Inter", "Maple Mono NF", "SF Pro Text", "Helvetica Neue", sans-serif !important;
              --font-code: "Maple Mono NF", "JetBrains Mono", ui-monospace, monospace !important;

              --background-primary: var(--base00) !important;
              --background-secondary: var(--base01) !important;
              --background-secondary-alt: var(--base01) !important;
              --background-tertiary: var(--base01) !important;
              --background-accent: var(--base02) !important;
              --background-floating: var(--base01) !important;
              --background-mobile-primary: var(--base00) !important;
              --background-mobile-secondary: var(--base01) !important;
              --chat-background-default: var(--base00) !important;
              --channeltextarea-background: var(--base01) !important;
              --modal-background: var(--base01) !important;
              --modal-footer-background: var(--base01) !important;

              --text-normal: var(--base05) !important;
              --text-default: var(--base05) !important;
              --text-primary: var(--base05) !important;
              --text-secondary: var(--base04) !important;
              --text-muted: var(--base04) !important;
              --text-muted-on-default: var(--base04) !important;
              --text-low-contrast: var(--base04) !important;
              --text-link: var(--base0D) !important;
              --text-link-low-saturation: var(--base0C) !important;
              --text-brand: var(--base0D) !important;
              --text-danger: var(--base08) !important;
              --text-positive: var(--base0D) !important;
              --text-warning: var(--base08) !important;
              --header-primary: var(--base06) !important;
              --header-secondary: var(--base04) !important;
              --interactive-normal: var(--base04) !important;
              --interactive-hover: var(--base06) !important;
              --interactive-active: var(--base07) !important;
              --interactive-muted: var(--base03) !important;
              --channels-default: var(--base04) !important;
              --channel-icon: var(--base04) !important;
              --channel-text-area-placeholder: var(--base04) !important;
              --icon-primary: var(--base05) !important;
              --icon-secondary: var(--base04) !important;
              --icon-muted: var(--base03) !important;
              --control-brand-foreground: var(--base0D) !important;
              --control-brand-foreground-new: var(--base0D) !important;

              --button-danger-background: var(--base08) !important;
              --button-danger-background-hover: color-mix(in srgb, var(--base08) 88%, black) !important;
              --button-danger-text: var(--base00) !important;
              --button-filled-brand-background: var(--base0D) !important;
              --button-filled-brand-background-hover: color-mix(in srgb, var(--base0D) 88%, black) !important;
              --button-filled-brand-text: var(--base00) !important;
              --button-secondary-background: var(--base02) !important;
              --button-secondary-background-hover: var(--base03) !important;
              --button-secondary-background-active: var(--base03) !important;
              --button-secondary-text: var(--base05) !important;
              --button-outline-primary-text: var(--base05) !important;
              --button-outline-primary-text-hover: var(--base06) !important;
              --button-outline-primary-text-active: var(--base06) !important;
              --redesign-button-primary-text: var(--base00) !important;
              --redesign-button-secondary-text: var(--base05) !important;
              --redesign-button-secondary-alt-text: var(--base05) !important;
              --redesign-button-secondary-alt-pressed-text: var(--base06) !important;
              --redesign-button-danger-text: var(--base00) !important;
              --redesign-button-positive-text: var(--base00) !important;

              --input-background: var(--base01) !important;
              --input-placeholder-text: var(--base04) !important;
              --profile-gradient-primary-color: var(--base01) !important;
              --profile-gradient-secondary-color: var(--base01) !important;
            }

            /* Sidebar surfaces */
            [class*="sidebar_"],
            [class*="privateChannels_"],
            [class*="guilds_"],
            [class*="membersWrap_"],
            [class*="panels_"] {
              background-color: var(--base01) !important;
            }

            /* Main chat/content surfaces */
            [class*="chat_"],
            [class*="chatContent_"],
            [class*="content_"],
            [class*="messagesWrapper_"],
            [class*="scroller_"],
            [class*="container_"] {
              background-color: var(--base00) !important;
              color: var(--base05) !important;
            }

            /* Force text color across Discord UI text-bearing elements. */
            [class*="text_"],
            [class*="name_"],
            [class*="username_"],
            [class*="messageContent_"],
            [class*="markup_"],
            [class*="title_"],
            [class*="subtitle_"],
            [class*="description_"],
            [class*="channelName_"],
            [class*="topic_"],
            [class*="placeholder_"],
            [class*="defaultColor_"],
            [class*="contents_"],
            span,
            p,
            h1,
            h2,
            h3,
            h4,
            h5,
            h6,
            label {
              color: var(--base05) !important;
            }

            [class*="textMuted_"],
            [class*="subtext_"],
            [class*="hint_"],
            [class*="meta_"],
            [class*="timestamp_"] {
              color: var(--base04) !important;
            }

            /* Titlebar */
            [class*="titleBar_"],
            [class*="bar_"][class*="titleBar"],
            [class*="typeWindows_"],
            [class*="winButton_"] {
              background-color: var(--base00) !important;
              color: var(--base05) !important;
            }

            /* Buttons + controls */
            button,
            [role="button"],
            [class*="lookFilled_"],
            [class*="lookOutlined_"],
            [class*="lookLink_"],
            [class*="input_"],
            [class*="select_"],
            [class*="option_"],
            [class*="item_"],
            [class*="bd-select"],
            [class*="bd-button"] {
              color: var(--base05) !important;
            }
          '';

        };
      };
    };

  # Dock registration: Vesktop owns its dock entry (order 130 in `dock.nix`).
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      dendritic.dock.apps = lib.mkOrder 130 [
        "${pkgs.vesktop}/Applications/Vesktop.app"
      ];
    };
}
