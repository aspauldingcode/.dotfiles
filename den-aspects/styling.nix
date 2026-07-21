{ inputs, den, ... }:
let
  selection = import ../theme-selection.nix;
  selectedName = selection.name or "stylix";
  selectedLight = selection.schemes.light or null;
  selectedDark = selection.schemes.dark or null;

  # Theme option declarations shared across all three module classes
  # (NixOS, nix-darwin, home-manager). Inlined here so theme options
  # always come along with styling regardless of class.
  themeOptionsModule =
    { lib, ... }:
    {
      options.dendritic.theme.name = lib.mkOption {
        type = lib.types.str;
        default = selectedName;
        description = "Human-readable theme name used by generated browser themes.";
      };

      options.dendritic.theme.variant = lib.mkOption {
        type = lib.types.enum [
          "dark"
          "light"
        ];
        default = "dark";
        description = "Global UI variant used to select Stylix palette.";
      };

      options.dendritic.theme.schemes.light = lib.mkOption {
        type = lib.types.str;
        default =
          if selectedLight != null then selectedLight else throw "theme-selection.nix must set schemes.light";
        description = "Base16 scheme basename for light mode (without .yaml).";
      };

      options.dendritic.theme.schemes.dark = lib.mkOption {
        type = lib.types.str;
        default =
          if selectedDark != null then selectedDark else throw "theme-selection.nix must set schemes.dark";
        description = "Base16 scheme basename for dark mode (without .yaml).";
      };
    };

  # ── Home Manager styling module ───────────────────────────────────────
  # Defined ONCE as a let-bound deferred module. Used in two places:
  #   1. `den.aspects.styling.homeManager` — picked up by future
  #      `den.homes.*` consumers via aspect resolution.
  #   2. `flake.modules.homeManager.dendritic` — picked up by current
  #      embedded HM users (the `home-manager.users.<user>` blocks inside
  #      mba, mba-dark, mba-asahi, nixos-test, microvm host files).
  # Both surfaces hold the same deferredModule, so there's no duplication
  # and no bridge indirection.
  stylingHmModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      desiredVariant = config.dendritic.theme.variant;
      schemeName =
        if desiredVariant == "light" then
          config.dendritic.theme.schemes.light
        else
          config.dendritic.theme.schemes.dark;
      stylixScheme = "${pkgs.base16-schemes}/share/themes/${schemeName}.yaml";
      colors = config.lib.stylix.colors.withHashtag;
      paletteVariant = lib.attrByPath [ "stylix" "polarity" ] "dark" config;
    in
    {
      imports = [ themeOptionsModule ];

      config = {
        stylix = {
          enable = true;
          polarity = desiredVariant;
          base16Scheme = lib.mkForce stylixScheme;
          override = {
            slug = "stylix";
            scheme = "stylix";
          };
          # Prefer curated nixos-artwork; dendritic.wallpaper overrides when enabled.
          image = lib.mkDefault pkgs.nixos-artwork.wallpapers.moonscape.gnomeFilePath;

          targets.vscode.enable = true;
          targets.ghostty.enable = true;
          targets.neovim.enable = false;
          targets.neovide.enable = false;
          targets.nixvim.enable = true;
          targets.spicetify.enable = lib.mkForce true;
          # qtct + Kvantum — QtPass (Qt5) and Dolphin (Qt6/KF) need this, not gtk3.
          targets.qt.enable = !isDarwin;
          targets.firefox.profileNames = [ "default" ];
        };

        home.file."colors.toml".text = ''
          [stylix]
          variant = "${paletteVariant}"

          [palette]
          base00 = "${colors.base00}"
          base01 = "${colors.base01}"
          base02 = "${colors.base02}"
          base03 = "${colors.base03}"
          base04 = "${colors.base04}"
          base05 = "${colors.base05}"
          base06 = "${colors.base06}"
          base07 = "${colors.base07}"
          base08 = "${colors.base08}"
          base09 = "${colors.base09}"
          base0A = "${colors.base0A}"
          base0B = "${colors.base0B}"
          base0C = "${colors.base0C}"
          base0D = "${colors.base0D}"
          base0E = "${colors.base0E}"
          base0F = "${colors.base0F}"
        '';

        # ── Stylix-themed Firefox UI ──────────────────────────────────
        programs.firefox.profiles =
          let
            c = config.lib.stylix.colors.withHashtag;

            commonCss = ''
              :root {
                --base00: ${c.base00}; --base01: ${c.base01}; --base02: ${c.base02}; --base03: ${c.base03};
                --base04: ${c.base04}; --base05: ${c.base05}; --base06: ${c.base06}; --base07: ${c.base07};
                --base08: ${c.base08}; --base09: ${c.base09}; --base0A: ${c.base0A}; --base0B: ${c.base0B};
                --base0C: ${c.base0C}; --base0D: ${c.base0D}; --base0E: ${c.base0E}; --base0F: ${c.base0F};
              }
            '';

            stylixUserChrome = commonCss + ''
              /* Aggressive UI Overrides */
              :root {
                --lwt-accent-color: var(--base00) !important;
                --lwt-text-color: var(--base05) !important;
                --toolbar-bgcolor: var(--base00) !important;
                --toolbar-color: var(--base05) !important;
                --toolbar-field-background-color: var(--base01) !important;
                --toolbar-field-color: var(--base05) !important;
                --toolbar-field-border-color: var(--base03) !important;
                --toolbar-field-focus-background-color: var(--base01) !important;
                --toolbar-field-focus-color: var(--base05) !important;
                --toolbar-field-focus-border-color: var(--base0D) !important;
                --lwt-selected-tab-background-color: var(--base02) !important;
                --lwt-tab-text-color: var(--base05) !important;
                --lwt-background-tab-text-color: var(--base04) !important;
                --lwt-tab-line-color: var(--base0D) !important;
                --tab-line-color: var(--base0D) !important;
                --toolbar-field-focus-background-color: var(--base02) !important;
                --toolbar-field-focus-border-color: var(--base0D) !important;
                --arrowpanel-background: var(--base01) !important;
                --arrowpanel-color: var(--base05) !important;
                --arrowpanel-border-color: var(--base03) !important;
                --panel-background: var(--base01) !important;
                --panel-color: var(--base05) !important;
                --panel-border-color: var(--base03) !important;
                --panel-separator-color: var(--base03) !important;
                --panel-item-hover-bgcolor: var(--base02) !important;
                --panel-item-active-bgcolor: var(--base03) !important;
                --button-bgcolor: var(--base02) !important;
                --button-hover-bgcolor: var(--base03) !important;
                --button-active-bgcolor: var(--base03) !important;
                --button-color: var(--base05) !important;
              }

              #nav-bar, #TabsToolbar, #PersonalToolbar, #navigator-toolbox, #sidebar-box, #sidebar-header {
                background-color: var(--base00) !important;
                background-image: none !important;
                color: var(--base05) !important;
                border: none !important;
                box-shadow: none !important;
              }

              .toolbarbutton-icon {
                fill: var(--base05) !important;
                fill-opacity: 1 !important;
              }
              .toolbarbutton-1:not([disabled]):hover .toolbarbutton-icon,
              .toolbarbutton-1:not([disabled])[open] .toolbarbutton-icon {
                fill: var(--base0D) !important;
              }

              .tabbrowser-tab[selected="true"] .tab-background,
              .tab-background[selected="true"] {
                background-color: var(--base02) !important;
                background-image: none !important;
                border-color: var(--base03) !important;
              }

              .tabbrowser-tab[selected="true"] .tab-label {
                color: var(--base06) !important;
              }

              .tabbrowser-tab:not([selected="true"]) .tab-background {
                background-color: var(--base01) !important;
              }

              .tab-line[selected="true"] {
                background-color: var(--base0D) !important;
              }

              .tab-throbber,
              .tab-throbber[busy],
              .tab-throbber[progress],
              .tabbrowser-tab[busy] .tab-icon-image,
              .tabbrowser-tab[progress] .tab-icon-image {
                fill: var(--base0D) !important;
                color: var(--base0D) !important;
              }

              .tab-background[selected] {
                outline: none !important;
                border: 2px solid transparent !important;
                box-shadow: none !important;
                background-clip: padding-box !important;
              }
              .tab-background[selected] > .tab-context-line {
                margin: -5px 0 0 !important;
              }
              .tabbrowser-tab[selected] > .tab-stack::before {
                content: "";
                display: flex;
                min-height: inherit;
                border-radius: var(--tab-border-radius);
                grid-area: 1 / 1;
                margin-block: var(--tab-block-margin);
                background-color: var(--base07) !important;
              }

              #tabs-newtab-button .toolbarbutton-icon,
              #new-tab-button .toolbarbutton-icon {
                fill: var(--base05) !important;
              }
              #tabs-newtab-button,
              #new-tab-button {
                background-color: transparent !important;
                border: none !important;
              }
              #tabs-newtab-button > .toolbarbutton-badge-stack,
              #new-tab-button > .toolbarbutton-badge-stack {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
              }
              #tabs-newtab-button:hover > .toolbarbutton-badge-stack,
              #new-tab-button:hover > .toolbarbutton-badge-stack {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
              }

              #urlbar-background,
              #searchbar,
              .searchbar-textbox {
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
                color: var(--base05) !important;
              }

              #urlbar {
                --urlbar-box-bgcolor: var(--base01) !important;
                --urlbar-box-hover-bgcolor: var(--base02) !important;
                --urlbar-box-active-bgcolor: var(--base02) !important;
                --urlbar-box-focus-bgcolor: var(--base02) !important;
              }

              #urlbar:not([focused="true"]) #urlbar-background {
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
              }

              #urlbar[focused="true"] #urlbar-background {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                box-shadow: 0 0 3px var(--base0D) !important;
              }

              #urlbar-input,
              #searchbar input {
                color: var(--base06) !important;
              }

              #identity-box.extensionPage #identity-icon-box,
              #identity-box.extensionPage #identity-permission-box,
              #identity-box.extensionPage #identity-icon-labels {
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
                color: var(--base05) !important;
              }

              #identity-box.chromeUI #identity-icon-box,
              #identity-box.chromeUI #identity-permission-box,
              #identity-box.chromeUI #identity-icon-labels,
              #identity-box.localResource #identity-icon-box,
              #identity-box.localResource #identity-permission-box,
              #identity-box.localResource #identity-icon-labels {
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
                color: var(--base05) !important;
              }

              #identity-icon-box,
              #identity-permission-box,
              #identity-icon-labels {
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
                color: var(--base05) !important;
              }

              #urlbar[focused="true"] #identity-box.extensionPage #identity-icon-box,
              #urlbar[focused="true"] #identity-box.extensionPage #identity-permission-box,
              #urlbar[focused="true"] #identity-box.extensionPage #identity-icon-labels {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                color: var(--base06) !important;
              }

              #urlbar[focused="true"] #identity-box.chromeUI #identity-icon-box,
              #urlbar[focused="true"] #identity-box.chromeUI #identity-permission-box,
              #urlbar[focused="true"] #identity-box.chromeUI #identity-icon-labels,
              #urlbar[focused="true"] #identity-box.localResource #identity-icon-box,
              #urlbar[focused="true"] #identity-box.localResource #identity-permission-box,
              #urlbar[focused="true"] #identity-box.localResource #identity-icon-labels {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                color: var(--base06) !important;
              }

              #identity-box.extensionPage #identity-icon-label {
                color: var(--base05) !important;
              }

              #identity-box.chromeUI #identity-icon-label,
              #identity-box.localResource #identity-icon-label {
                color: var(--base05) !important;
              }

              button,
              toolbarbutton,
              .toolbarbutton-1,
              .button-background,
              .dialog-button,
              .popup-notification-button,
              moz-button::part(button) {
                --button-bgcolor: var(--base02) !important;
                --button-hover-bgcolor: var(--base03) !important;
                --button-active-bgcolor: var(--base03) !important;
                --button-color: var(--base05) !important;
                appearance: none !important;
                -moz-appearance: none !important;
                background-color: var(--base02) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
                box-shadow: none !important;
              }

              button:hover,
              toolbarbutton:hover,
              .toolbarbutton-1:hover,
              .button-background:hover,
              .dialog-button:hover,
              .popup-notification-button:hover,
              moz-button:hover::part(button) {
                background-color: var(--base03) !important;
                color: var(--base06) !important;
                border-color: var(--base03) !important;
              }

              button[default],
              button.primary,
              button[dlgtype="accept"],
              .popup-notification-primary-button,
              .dialog-button[default],
              moz-button[default]::part(button),
              moz-button[variant="primary"]::part(button),
              moz-button.popup-notification-primary-button::part(button) {
                background-color: var(--base0D) !important;
                color: var(--base00) !important;
                border-color: var(--base0D) !important;
              }

              button[default]:hover,
              button.primary:hover,
              button[dlgtype="accept"]:hover,
              .popup-notification-primary-button:hover,
              .dialog-button[default]:hover,
              moz-button[default]:hover::part(button),
              moz-button[variant="primary"]:hover::part(button),
              moz-button.popup-notification-primary-button:hover::part(button) {
                background-color: var(--base0C) !important;
                color: var(--base00) !important;
                border-color: var(--base0C) !important;
              }

              #nav-bar toolbarbutton,
              #TabsToolbar toolbarbutton,
              #PersonalToolbar toolbarbutton {
                background-color: transparent !important;
                border: none !important;
                box-shadow: none !important;
              }
              #nav-bar toolbarbutton > .toolbarbutton-badge-stack,
              #nav-bar toolbarbutton > .toolbarbutton-text,
              #TabsToolbar toolbarbutton > .toolbarbutton-badge-stack,
              #TabsToolbar toolbarbutton > .toolbarbutton-text,
              #PersonalToolbar toolbarbutton > .toolbarbutton-badge-stack,
              #PersonalToolbar toolbarbutton > .toolbarbutton-text {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
                color: var(--base05) !important;
              }
              #nav-bar toolbarbutton:hover > .toolbarbutton-badge-stack,
              #nav-bar toolbarbutton:hover > .toolbarbutton-text,
              #TabsToolbar toolbarbutton:hover > .toolbarbutton-badge-stack,
              #TabsToolbar toolbarbutton:hover > .toolbarbutton-text,
              #PersonalToolbar toolbarbutton:hover > .toolbarbutton-badge-stack,
              #PersonalToolbar toolbarbutton:hover > .toolbarbutton-text {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                color: var(--base06) !important;
              }

              #sidebar-button > .toolbarbutton-badge-stack,
              #alltabs-button > .toolbarbutton-badge-stack,
              #tabs-alltabs-button > .toolbarbutton-badge-stack,
              #PanelUI-button > .toolbarbutton-badge-stack,
              #unified-extensions-button > .toolbarbutton-badge-stack,
              #fxa-toolbar-menu-button > .toolbarbutton-badge-stack,
              #firefox-view-button > .toolbarbutton-badge-stack,
              #history-panelmenu > .toolbarbutton-badge-stack,
              #reload-button > .toolbarbutton-badge-stack,
              #stop-button > .toolbarbutton-badge-stack,
              #back-button > .toolbarbutton-badge-stack,
              #forward-button > .toolbarbutton-badge-stack {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
              }
              #sidebar-button:hover > .toolbarbutton-badge-stack,
              #alltabs-button:hover > .toolbarbutton-badge-stack,
              #tabs-alltabs-button:hover > .toolbarbutton-badge-stack,
              #PanelUI-button:hover > .toolbarbutton-badge-stack,
              #unified-extensions-button:hover > .toolbarbutton-badge-stack,
              #fxa-toolbar-menu-button:hover > .toolbarbutton-badge-stack,
              #firefox-view-button:hover > .toolbarbutton-badge-stack,
              #history-panelmenu:hover > .toolbarbutton-badge-stack,
              #reload-button:hover > .toolbarbutton-badge-stack,
              #stop-button:hover > .toolbarbutton-badge-stack,
              #back-button:hover > .toolbarbutton-badge-stack,
              #forward-button:hover > .toolbarbutton-badge-stack {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
              }
              #sidebar-button .toolbarbutton-icon,
              #alltabs-button .toolbarbutton-icon,
              #tabs-alltabs-button .toolbarbutton-icon,
              #unified-extensions-button .toolbarbutton-icon,
              #PanelUI-button .toolbarbutton-icon,
              #fxa-toolbar-menu-button .toolbarbutton-icon,
              #firefox-view-button .toolbarbutton-icon,
              #history-panelmenu .toolbarbutton-icon,
              #reload-button .toolbarbutton-icon,
              #stop-button .toolbarbutton-icon,
              #back-button .toolbarbutton-icon,
              #forward-button .toolbarbutton-icon {
                fill: var(--base05) !important;
              }
              #sidebar-button:hover .toolbarbutton-icon,
              #alltabs-button:hover .toolbarbutton-icon,
              #tabs-alltabs-button:hover .toolbarbutton-icon,
              #unified-extensions-button:hover .toolbarbutton-icon,
              #PanelUI-button:hover .toolbarbutton-icon,
              #fxa-toolbar-menu-button:hover .toolbarbutton-icon,
              #firefox-view-button:hover .toolbarbutton-icon,
              #history-panelmenu:hover .toolbarbutton-icon,
              #reload-button:hover .toolbarbutton-icon,
              #stop-button:hover .toolbarbutton-icon,
              #back-button:hover .toolbarbutton-icon,
              #forward-button:hover .toolbarbutton-icon {
                fill: var(--base0D) !important;
              }

              #fxa-toolbar-menu-button,
              #fxa-toolbar-menu-button .toolbarbutton-icon,
              #fxa-toolbar-menu-button image,
              #fxa-toolbar-menu-button .toolbarbutton-badge-stack,
              #fxa-toolbar-menu-button .toolbarbutton-badge-stack > image,
              #fxa-avatar-image,
              #fxa-avatar-image image,
              #fxa-avatar-image > image {
                -moz-context-properties: fill, stroke, fill-opacity, stroke-opacity !important;
                fill: var(--base05) !important;
                stroke: var(--base05) !important;
                color: var(--base05) !important;
              }
              #fxa-toolbar-menu-button:hover .toolbarbutton-icon,
              #fxa-toolbar-menu-button:hover image,
              #fxa-toolbar-menu-button:hover .toolbarbutton-badge-stack > image,
              #fxa-toolbar-menu-button:hover #fxa-avatar-image,
              #fxa-toolbar-menu-button:hover #fxa-avatar-image image {
                fill: var(--base0D) !important;
                stroke: var(--base0D) !important;
                color: var(--base0D) !important;
              }

              #sidebar-main,
              #sidebar-box,
              #sidebar-header {
                background-color: var(--base00) !important;
              }
              #sidebar-switcher-target,
              #viewButton,
              #sidebar-close {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
                color: var(--base05) !important;
              }
              #sidebar-switcher-target:hover,
              #viewButton:hover,
              #sidebar-close:hover {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                color: var(--base06) !important;
              }
              #sidebar-placesTree treechildren::-moz-tree-row {
                background-color: var(--base00) !important;
              }
              #sidebar-placesTree treechildren::-moz-tree-row(hover) {
                background-color: var(--base01) !important;
              }
              #sidebar-placesTree treechildren::-moz-tree-row(selected) {
                background-color: var(--base02) !important;
              }

              #sidebar-main toolbarbutton,
              #sidebar-main button,
              #sidebar-main [role="button"],
              #sidebar-main .subviewbutton,
              #sidebar-main [id*="sidebar"][id*="button"],
              #sidebar-main [class*="sidebar"][class*="button"] {
                background-color: transparent !important;
                border: none !important;
                box-shadow: none !important;
                color: var(--base05) !important;
              }
              #sidebar-main toolbarbutton > .toolbarbutton-badge-stack,
              #sidebar-main toolbarbutton > .toolbarbutton-text,
              #sidebar-main .button-background,
              #sidebar-main .subviewbutton,
              #sidebar-main #sidebar-customize-button,
              #sidebar-main #sidebar-button-bookmarks,
              #sidebar-main #sidebar-button-history,
              #sidebar-main #sidebar-button-syncedtabs,
              #sidebar-main #sidebar-button-chat {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
                color: var(--base05) !important;
              }
              #sidebar-main toolbarbutton:hover > .toolbarbutton-badge-stack,
              #sidebar-main toolbarbutton:hover > .toolbarbutton-text,
              #sidebar-main .button-background:hover,
              #sidebar-main .subviewbutton:hover,
              #sidebar-main #sidebar-customize-button:hover,
              #sidebar-main #sidebar-button-bookmarks:hover,
              #sidebar-main #sidebar-button-history:hover,
              #sidebar-main #sidebar-button-syncedtabs:hover,
              #sidebar-main #sidebar-button-chat:hover {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
                color: var(--base06) !important;
              }
              #sidebar-main .toolbarbutton-icon,
              #sidebar-main .subviewbutton-icon,
              #sidebar-main image {
                -moz-context-properties: fill, stroke !important;
                fill: var(--base05) !important;
                stroke: var(--base05) !important;
              }
              #sidebar-main toolbarbutton:hover .toolbarbutton-icon,
              #sidebar-main .subviewbutton:hover .subviewbutton-icon,
              #sidebar-main button:hover image {
                fill: var(--base0D) !important;
                stroke: var(--base0D) !important;
              }

              #tab-modal-prompt-box,
              .tabmodalprompt-mainContainer,
              .tabmodalprompt-infoBody,
              .tabmodalprompt-buttonContainer,
              #commonDialog,
              #commonDialog > dialog,
              #commonDialog .dialogFrame,
              #commonDialog .dialogOverlay,
              #commonDialog .contentPromptDialog {
                background-color: var(--base01) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
              }

              .tabmodalprompt-mainContainer button,
              .tabmodalprompt-mainContainer .dialog-button,
              .tabmodalprompt-buttonContainer > button,
              .tabmodalprompt-buttonContainer > .dialog-button,
              .tabmodalprompt-buttonContainer button[default],
              .tabmodalprompt-buttonContainer button[dlgtype="accept"],
              .tabmodalprompt-buttonContainer button[dlgtype="cancel"],
              #tabmodalprompt-button0,
              #tabmodalprompt-button1,
              #commonDialog button,
              #commonDialog .dialog-button,
              #commonDialog .dialog-button-box .dialog-button,
              #commonDialog button[default],
              #commonDialog button[dlgtype="accept"],
              #commonDialog button[dlgtype="cancel"] {
                background-color: var(--base02) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
              }

              .tabmodalprompt-mainContainer button:hover,
              .tabmodalprompt-mainContainer .dialog-button:hover,
              .tabmodalprompt-buttonContainer > button:hover,
              .tabmodalprompt-buttonContainer > .dialog-button:hover,
              #commonDialog button:hover,
              #commonDialog .dialog-button:hover {
                background-color: var(--base03) !important;
                color: var(--base06) !important;
              }

              .tabmodalprompt-mainContainer button[default],
              .tabmodalprompt-mainContainer .dialog-button[default],
              .tabmodalprompt-buttonContainer button[default],
              .tabmodalprompt-buttonContainer button[dlgtype="accept"],
              #commonDialog button[default],
              #commonDialog .dialog-button[default],
              #commonDialog button[dlgtype="accept"] {
                background-color: var(--base0D) !important;
                color: var(--base00) !important;
                border-color: var(--base0D) !important;
              }

              .tabmodalprompt-mainContainer button[default]:hover,
              .tabmodalprompt-mainContainer .dialog-button[default]:hover,
              .tabmodalprompt-buttonContainer button[default]:hover,
              .tabmodalprompt-buttonContainer button[dlgtype="accept"]:hover,
              #commonDialog button[default]:hover,
              #commonDialog .dialog-button[default]:hover,
              #commonDialog button[dlgtype="accept"]:hover {
                background-color: var(--base0C) !important;
                color: var(--base00) !important;
                border-color: var(--base0C) !important;
              }

              #notification-popup,
              #notification-popup popupnotification,
              #notification-popup popupnotificationcontent,
              .popup-notification-panel,
              .popup-notification-body-container,
              .popup-notification-content,
              .popup-notification-description {
                background-color: var(--base01) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
              }

              #notification-popup popupnotification {
                --panel-background: var(--base01) !important;
                --panel-color: var(--base05) !important;
                --panel-border-color: var(--base03) !important;
                --button-bgcolor: var(--base02) !important;
                --button-hover-bgcolor: var(--base03) !important;
                --button-active-bgcolor: var(--base03) !important;
                --button-color: var(--base05) !important;
                --button-primary-bgcolor: var(--base0D) !important;
                --button-primary-hover-bgcolor: var(--base0C) !important;
                --button-primary-active-bgcolor: var(--base0C) !important;
                --button-primary-color: var(--base00) !important;
                --checkbox-unchecked-bgcolor: var(--base01) !important;
                --checkbox-unchecked-hover-bgcolor: var(--base02) !important;
                --checkbox-checked-bgcolor: var(--base0D) !important;
                --checkbox-checked-color: var(--base00) !important;
                --checkbox-border-color: var(--base03) !important;
              }

              #notification-popup .popup-notification-primary-button,
              #notification-popup moz-button.popup-notification-primary-button,
              #notification-popup .popup-notification-primary-button::part(button),
              #notification-popup .popup-notification-secondary-button,
              #notification-popup moz-button.popup-notification-secondary-button,
              #notification-popup .popup-notification-secondary-button::part(button),
              #notification-popup button,
              #notification-popup moz-button::part(button),
              #notification-popup .popup-notification-button {
                appearance: none !important;
                background-color: var(--base02) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
                box-shadow: none !important;
              }

              #notification-popup .popup-notification-primary-button,
              #notification-popup moz-button.popup-notification-primary-button,
              #notification-popup .popup-notification-primary-button::part(button) {
                appearance: none !important;
                background-color: var(--base0D) !important;
                color: var(--base00) !important;
                border-color: var(--base0D) !important;
              }

              #notification-popup .popup-notification-primary-button:hover,
              #notification-popup moz-button.popup-notification-primary-button:hover,
              #notification-popup moz-button.popup-notification-primary-button:hover::part(button),
              #notification-popup .popup-notification-primary-button::part(button):hover,
              #notification-popup .popup-notification-secondary-button:hover,
              #notification-popup moz-button.popup-notification-secondary-button:hover,
              #notification-popup moz-button.popup-notification-secondary-button:hover::part(button),
              #notification-popup .popup-notification-secondary-button::part(button):hover,
              #notification-popup button:hover,
              #notification-popup moz-button:hover::part(button),
              #notification-popup .popup-notification-button:hover {
                background-color: var(--base03) !important;
                color: var(--base06) !important;
              }

              #notification-popup .popup-notification-primary-button:hover,
              #notification-popup moz-button.popup-notification-primary-button:hover,
              #notification-popup moz-button.popup-notification-primary-button:hover::part(button),
              #notification-popup .popup-notification-primary-button::part(button):hover {
                background-color: var(--base0C) !important;
                color: var(--base00) !important;
                border-color: var(--base0C) !important;
              }

              #notification-popup .popup-notification-checkbox > .checkbox-check,
              #notification-popup .popup-notification-checkbox .checkbox-check,
              #notification-popup .popup-notification-checkbox::part(checkbox),
              #notification-popup checkbox.popup-notification-checkbox > .checkbox-check {
                appearance: none !important;
                background-color: var(--base01) !important;
                border-color: var(--base03) !important;
                color: var(--base05) !important;
              }

              #notification-popup .popup-notification-checkbox[checked="true"] > .checkbox-check,
              #notification-popup .popup-notification-checkbox[checked] > .checkbox-check,
              #notification-popup checkbox.popup-notification-checkbox[checked="true"] > .checkbox-check {
                background-color: var(--base0D) !important;
                border-color: var(--base0D) !important;
                color: var(--base00) !important;
              }

              #notification-popup .popup-notification-checkbox .checkbox-icon,
              #notification-popup .popup-notification-checkbox > .checkbox-check::before {
                -moz-context-properties: fill, stroke !important;
                fill: var(--base00) !important;
                stroke: var(--base00) !important;
              }

              #notification-popup .popup-notification-checkbox > .checkbox-label-box > .checkbox-label {
                color: var(--base05) !important;
                opacity: 1 !important;
              }

              #appMenu-popup {
                --arrowpanel-background: var(--base00) !important;
                --arrowpanel-color: var(--base05) !important;
                --arrowpanel-border-color: var(--base03) !important;
              }

              #customization-container {
                background-color: var(--base00) !important;
              }
              #customization-done-button {
                background-color: var(--base02) !important;
                color: var(--base05) !important;
                border-color: var(--base03) !important;
              }
              #customization-done-button:hover {
                background-color: var(--base03) !important;
                border-color: var(--base0D) !important;
              }
              #customization-done-button:active {
                background-color: var(--base04) !important;
              }

              .urlbarView-row {
                color: var(--base05) !important;
              }
              .urlbarView {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }
              .urlbarView-row[selected] {
                background-color: var(--base02) !important;
                color: var(--base06) !important;
              }
              .urlbarView-type-icon {
                fill: var(--base05) !important;
              }
              .urlbarView-action {
                color: var(--base04) !important;
              }

              #unified-extensions-view,
              .panel-arrowcontent {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }
              .unified-extensions-item {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }
              .unified-extensions-item:hover {
                background-color: var(--base01) !important;
              }
              #unified-extensions-manage-extensions {
                background-color: var(--base01) !important;
                color: var(--base05) !important;
              }
              #unified-extensions-manage-extensions:hover {
                background-color: var(--base02) !important;
              }

              .webextension-browser-action {
                filter: grayscale(100%) brightness(1.2) contrast(1.2) opacity(0.7)
                  drop-shadow(0 0 0 var(--base05)) !important;
              }
              toolbarbutton.webextension-browser-action .toolbarbutton-icon,
              #unified-extensions-button .toolbarbutton-icon,
              #unified-extensions-panel .toolbarbutton-icon {
                fill: var(--base05) !important;
                fill-opacity: 1 !important;
              }
              toolbarbutton.webextension-browser-action:hover .toolbarbutton-icon,
              #unified-extensions-button:hover .toolbarbutton-icon,
              #unified-extensions-panel toolbarbutton:hover .toolbarbutton-icon {
                fill: var(--base0D) !important;
              }
              #unified-extensions-panel .unified-extensions-item-action-button,
              #unified-extensions-panel toolbarbutton {
                color: var(--base05) !important;
                background-color: var(--base00) !important;
              }
              #unified-extensions-panel .unified-extensions-item-action-button:hover,
              #unified-extensions-panel toolbarbutton:hover {
                color: var(--base06) !important;
                background-color: var(--base01) !important;
              }

              #sidebar-header,
              #sidebar-switcher-target,
              #viewButton {
                background-color: var(--base01) !important;
                border: 1px solid var(--base03) !important;
                color: var(--base05) !important;
              }
              #sidebar-switcher-target:hover,
              #viewButton:hover {
                background-color: var(--base02) !important;
                border-color: var(--base0D) !important;
              }
              #sidebarMenu-popup {
                --arrowpanel-background: var(--base00) !important;
                --arrowpanel-color: var(--base05) !important;
                --arrowpanel-border-color: var(--base03) !important;
              }
              #sidebarMenu-popup menuitem:hover {
                background-color: var(--base01) !important;
              }

              .panel-arrowbox,
              .panel-arrow,
              .panel-viewstack,
              .panel-mainview,
              .panel-subview {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }

              .message-bar,
              .message-bar-content,
              .message-bar-button {
                background-color: var(--base00) !important;
                color: var(--base05) !important;
              }

              .checkbox-check {
                background-color: transparent !important;
                border: 1px solid var(--base04) !important;
              }
              .checkbox-label {
                color: var(--base04) !important;
              }
              .text-link {
                color: var(--base0D) !important;
              }
              .text-link:hover {
                color: var(--base0C) !important;
                text-decoration: none !important;
              }

              menupopup, panel {
                --panel-background: var(--base01) !important;
                --panel-color: var(--base05) !important;
                --panel-border-color: var(--base03) !important;
              }

              menuitem, menu {
                appearance: none !important;
                color: var(--base05) !important;
              }

              menuitem[_moz-menuactive="true"], menu[_moz-menuactive="true"] {
                background-color: var(--base02) !important;
                color: var(--base0D) !important;
              }
            '';

            stylixUserContent = commonCss + ''
              @-moz-document url-prefix(about:), url-prefix(chrome:) {
                :root {
                  --in-content-page-background: var(--base00) !important;
                  --in-content-page-color: var(--base05) !important;
                  --in-content-box-background: var(--base01) !important;
                  --in-content-primary-button-background: var(--base0D) !important;
                  --in-content-primary-button-background-hover: var(--base0C) !important;
                  --in-content-primary-button-text-color: var(--base00) !important;
                  --in-content-button-background: var(--base02) !important;
                  --in-content-button-background-hover: var(--base03) !important;
                  --in-content-button-text-color: var(--base05) !important;
                  --in-content-border-color: var(--base03) !important;
                  --in-content-box-border-color: var(--base03) !important;
                  --in-content-deemphasized-text: var(--base04) !important;
                  --in-content-accent-color: var(--base0D) !important;
                  --in-content-accent-color-active: var(--base0C) !important;
                  --in-content-table-background: var(--base01) !important;
                  --in-content-table-border-color: var(--base03) !important;
                  --in-content-item-hover: var(--base02) !important;
                  --in-content-item-selected: var(--base02) !important;
                }
                body {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                }
                .dialogBox,
                .dialogOverlay,
                .contentPromptDialog {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                button,
                html|button,
                input[type="button"],
                input[type="submit"],
                input[type="reset"],
                .button,
                .dialog-button,
                .popup-notification-button,
                .popup-notification-secondary-button,
                .popup-notification-primary-button,
                moz-button::part(button) {
                  appearance: none !important;
                  -moz-appearance: none !important;
                  background-color: var(--base02) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                  box-shadow: none !important;
                }

                button:hover,
                html|button:hover,
                input[type="button"]:hover,
                input[type="submit"]:hover,
                input[type="reset"]:hover,
                .button:hover,
                .dialog-button:hover,
                .popup-notification-button:hover,
                .popup-notification-secondary-button:hover,
                moz-button:hover::part(button) {
                  background-color: var(--base03) !important;
                  color: var(--base06) !important;
                  border-color: var(--base03) !important;
                }

                button[default],
                button.primary,
                button[dlgtype="accept"],
                .button-primary,
                .popup-notification-primary-button,
                moz-button[default]::part(button),
                moz-button[variant="primary"]::part(button),
                moz-button.popup-notification-primary-button::part(button) {
                  appearance: none !important;
                  -moz-appearance: none !important;
                  background-color: var(--base0D) !important;
                  color: var(--base00) !important;
                  border-color: var(--base0D) !important;
                }

                button[default]:hover,
                button.primary:hover,
                button[dlgtype="accept"]:hover,
                .button-primary:hover,
                .popup-notification-primary-button:hover,
                moz-button[default]:hover::part(button),
                moz-button[variant="primary"]:hover::part(button),
                moz-button.popup-notification-primary-button:hover::part(button) {
                  background-color: var(--base0C) !important;
                  color: var(--base00) !important;
                  border-color: var(--base0C) !important;
                }

                checkbox,
                input[type="checkbox"],
                .checkbox-check,
                .checkbox-icon {
                  accent-color: var(--base0D) !important;
                  border-color: var(--base03) !important;
                }
              }

              @-moz-document url-prefix(about:preferences) {
                :root {
                  --background-color-canvas: var(--base00) !important;
                  --background-color-box: var(--base00) !important;
                  --background-color-box-info: var(--base00) !important;
                  --background-color-overlay: var(--base00) !important;
                  --background-color-list-item-hover: var(--base01) !important;
                  --background-color-list-item-selected: var(--base01) !important;
                  --border-color: var(--base03) !important;
                  --border-color-selected: var(--base0D) !important;
                  --text-color: var(--base05) !important;
                  --text-color-deemphasized: var(--base04) !important;
                  --text-color-list-item-hover: var(--base06) !important;
                  --color-accent-primary: var(--base0D) !important;
                  --color-accent-primary-hover: var(--base0C) !important;
                  --color-accent-primary-active: var(--base0C) !important;
                  --color-accent-primary-selected: var(--base0D) !important;
                  --text-color-accent-primary: var(--base00) !important;
                  --text-color-accent-primary-selected: var(--base00) !important;
                  --background-color-critical: var(--base08) !important;
                  --text-color-error: var(--base08) !important;

                  --in-content-page-background: var(--base00) !important;
                  --in-content-page-color: var(--base05) !important;
                  --in-content-box-background: var(--base00) !important;
                  --in-content-box-border-color: var(--base03) !important;
                  --in-content-button-background: var(--base02) !important;
                  --in-content-button-background-hover: var(--base03) !important;
                  --in-content-button-text-color: var(--base05) !important;
                  --in-content-primary-button-background: var(--base0D) !important;
                  --in-content-primary-button-background-hover: var(--base0C) !important;
                  --in-content-primary-button-text-color: var(--base00) !important;
                  --in-content-table-background: var(--base00) !important;
                  --in-content-table-header-background: var(--base00) !important;
                  --in-content-table-border-color: var(--base03) !important;
                  --in-content-border-hover: var(--base03) !important;
                  --in-content-item-hover: var(--base01) !important;
                  --in-content-item-hover-text: var(--base06) !important;
                  --in-content-item-selected: var(--base02) !important;
                  --in-content-item-selected-text: var(--base06) !important;
                  --in-content-deemphasized-text: var(--base04) !important;
                  --checkbox-unchecked-bgcolor: var(--base01) !important;
                  --checkbox-unchecked-hover-bgcolor: var(--base02) !important;
                  --checkbox-checked-bgcolor: var(--base0D) !important;
                  --checkbox-checked-color: var(--base00) !important;
                  --link-color: var(--base0D) !important;
                  --link-color-hover: var(--base0C) !important;
                }

                html, body,
                #preferences-body,
                #preferences-container,
                #preferences-stack,
                #mainPrefPane,
                .main-content {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                }

                #category-box,
                #categories,
                #preferences-sidebar,
                .sticky-container {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                .pane-container {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                .category,
                .subcategory {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                }

                .category:hover,
                .subcategory:hover {
                  background-color: var(--base01) !important;
                  border-color: var(--base03) !important;
                }

                .category[selected],
                .subcategory[selected] {
                  background-color: var(--base01) !important;
                  color: var(--base06) !important;
                  border-color: var(--base03) !important;
                  box-shadow: inset 2px 0 0 var(--base0D) !important;
                }

                groupbox,
                .card,
                .settings-box,
                .content-blocking-category,
                .section,
                setting-group,
                setting-pane,
                setting-control,
                moz-card {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                .header,
                h1, h2, h3, h4,
                .title,
                .description,
                .text-link {
                  color: var(--base05) !important;
                }

                .description-deemphasized,
                .text-deemphasized,
                .help-link {
                  color: var(--base04) !important;
                }

                #policies-container,
                #enterprise-policy-container,
                .enterprise-policy-container,
                .info-box-container,
                .info-box,
                #isDefaultBox,
                #setDefaultPane,
                #isNotDefaultPane,
                #defaultBrowserNotification,
                .default-browser-notification,
                setting-group[groupid="defaultBrowser"],
                .notification-message,
                .notification-inner {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                .spotlight,
                setting-group.spotlight,
                setting-group[groupid="defaultBrowser"].spotlight {
                  background-color: color-mix(in srgb, var(--base0D) 16%, var(--base01)) !important;
                  outline-color: var(--base0D) !important;
                  border-color: var(--base0D) !important;
                  animation: none !important;
                }

                #searchInput,
                .search-container input,
                .search-textbox,
                .search-field {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                #searchInput:focus,
                .search-container input:focus {
                  background-color: var(--base00) !important;
                  border-color: var(--base0D) !important;
                  color: var(--base06) !important;
                }

                input[type="checkbox"],
                input[type="radio"],
                .checkbox-check,
                .radio-check {
                  accent-color: var(--base0D) !important;
                }

                button {
                  background-color: var(--base02) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                button:hover {
                  background-color: var(--base03) !important;
                  color: var(--base06) !important;
                }

                button.primary {
                  background-color: var(--base0D) !important;
                  color: var(--base00) !important;
                }

                button.primary:hover {
                  background-color: var(--base0C) !important;
                  color: var(--base00) !important;
                }

                radiogroup,
                radio,
                [role="radiogroup"],
                [role="radio"],
                .radio-group,
                .choice-button,
                .multi-choice-button,
                .single-choice-button,
                .radio-check,
                .radio-icon,
                .radio-label {
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                  background-color: transparent !important;
                }

                radio[selected="true"] .radio-check,
                .radio-check[selected="true"] {
                  background-color: var(--base0D) !important;
                  border-color: var(--base0D) !important;
                }

                checkbox,
                input[type="checkbox"],
                .checkbox-check,
                .checkbox-icon,
                .toggle-button {
                  border-color: var(--base03) !important;
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                }

                checkbox[checked="true"] .checkbox-check,
                input[type="checkbox"]:checked,
                .checkbox-check[checked="true"] {
                  background-color: var(--base0D) !important;
                  border-color: var(--base0D) !important;
                  color: var(--base00) !important;
                }

                menulist,
                menulist::part(label),
                menulist::part(icon),
                .menulist-label,
                .folder-menu-list,
                #downloadFolder,
                #downloadFolderButton,
                #translations-manage-description,
                #translations-manage-settings-button,
                #translations-manage-install-list,
                .translations-manage-language,
                .translations-manage-language > label,
                #translateBox,
                #translationsGroup,
                #dictionariesGroup,
                input[type="text"],
                input[type="search"] {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                #applicationsGroup,
                #filter,
                #handlersView,
                #handlersView richlistitem,
                #handlersView .actionsMenu,
                #handlersView .actionsMenu > .menulist-label,
                #handlersTable {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                  border-color: var(--base03) !important;
                }

                #handlersView richlistitem:hover,
                #handlersView richlistitem[selected],
                .content-blocking-category:hover,
                .setting-row:hover,
                .search-container:hover,
                setting-group:hover,
                setting-control:hover,
                .translations-manage-language:hover,
                moz-card:hover {
                  background-color: var(--base01) !important;
                  color: var(--base06) !important;
                  border-color: var(--base03) !important;
                }
              }
            '';
          in
          {
            default = {
              isDefault = true;
              id = 0;
              userChrome = stylixUserChrome;
              userContent = stylixUserContent;
            };
          };

        # ── GTK Theming ─────────────────────────────────────────────
        # Do not set gtk-application-prefer-dark-theme — libadwaita/portal-gnome
        # reject it (use AdwStyleManager / org.gnome.desktop.interface color-scheme,
        # already driven by Stylix / dendritic-appearance).
        gtk = {
          gtk4.theme = lib.mkForce null;
          enable = lib.mkDefault (!isDarwin);
        };

        # ── Qt Theming (Linux only) ─────────────────────────────────
        # Owned by stylix.targets.qt (qtct + kvantum Base16Kvantum).
        # dendritic-appearance refreshes kdeglobals / Kvantum from colors.toml.

        # ── Terminal env ────────────────────────────────────────────
        programs.zsh.initContent = ''
          export COLORTERM=truecolor
        '';

        # macOS appearance is the source of truth; darwin appearance-sync
        # detects AppleInterfaceStyle and activates matching prebuilt
        # profile. Do not push appearance from HM in the opposite direction.
      };
    };
in
{
  # ── Den styling aspect ──────────────────────────────────────────────
  # System-level (nixos + darwin) Stylix is unified via the `os` custom
  # class. HM-level Stylix lives in `homeManager`. The HM body is also
  # mirrored into `flake.modules.homeManager.dendritic` below so that
  # embedded HM users (`home-manager.users.<user>` inside the four
  # darwin/nixos hosts) pick it up via the existing dendritic monolith
  # without going through `den.homes`.
  den.aspects.styling = {
    nixos =
      { lib, config, ... }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];
        stylix.fonts.sizes = {
          terminal = 12;
          applications = 12;
          desktop = 11;
        };
        stylix.cursor = {
          package = config._module.args.pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        stylix.opacity = {
          terminal = 1.0;
          popups = 0.95;
        };
        specialisation = lib.mkDefault {
          light.configuration.dendritic.theme.variant = lib.mkForce "light";
          dark.configuration.dendritic.theme.variant = lib.mkForce "dark";
        };
      };

    darwin =
      { pkgs, ... }:
      {
        imports = [ inputs.stylix.darwinModules.stylix ];
        fonts.packages = [
          pkgs.maple-mono.NF
          pkgs.inter
          pkgs.noto-fonts
        ];
      };

    # ── Shared Stylix config (nixos + darwin) ────────────────────────
    # Written ONCE here; den's `os` class forwards it into BOTH the
    # nixos and darwin evaluations. Replaces what used to be the
    # duplicated bodies in `modules/styling.nix`.
    os =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        schemeName =
          if config.dendritic.theme.variant == "light" then
            config.dendritic.theme.schemes.light
          else
            config.dendritic.theme.schemes.dark;
        stylixScheme = "${pkgs.base16-schemes}/share/themes/${schemeName}.yaml";
      in
      {
        imports = [ themeOptionsModule ];

        stylix = {
          enable = true;
          enableReleaseChecks = false;
          polarity = config.dendritic.theme.variant;
          base16Scheme = lib.mkForce stylixScheme;
          override = {
            slug = "stylix";
            scheme = "stylix";
          };
          # Prefer curated nixos-artwork; dendritic.wallpaper overrides when enabled.
          image = lib.mkDefault pkgs.nixos-artwork.wallpapers.moonscape.gnomeFilePath;

          fonts = {
            monospace = {
              package = pkgs.maple-mono.NF;
              name = "Maple Mono NF";
            };
            sansSerif = {
              package = pkgs.inter;
              name = "Inter";
            };
            serif = {
              package = pkgs.noto-fonts;
              name = "Noto Serif";
            };
          };
        };
      };

    # Aspect-side HM Stylix body — picked up by `den.homes.*` consumers
    # via `includes`. Currently no consumer beyond mirror to
    # `flake.modules.homeManager.dendritic` below.
    homeManager = stylingHmModule;
  };

  # ── Mirror into the flake-parts HM dendritic monolith ────────────
  # The embedded HM users in mba/mba-dark/mba-asahi/nixos-test/microvm
  # all import `inputs.self.modules.homeManager.dendritic`. Defining
  # the same `stylingHmModule` here makes them pick up the HM Stylix
  # body without needing `den.homes.*` migration.
  flake.modules.homeManager.dendritic = stylingHmModule;
}
