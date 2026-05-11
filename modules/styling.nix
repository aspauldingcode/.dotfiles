{
  # ── NixOS Styling ─────────────────────────────────────────────
  flake.modules.nixos.styling = {
    pkgs,
    inputs,
    lib,
    ...
  }: {
    imports = [
      inputs.stylix.nixosModules.stylix
      ./theme.nix
    ];

    stylix = {
      enable = true;
      enableReleaseChecks = false;
      polarity = "dark";

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
        sizes = {
          terminal = 12;
          applications = 12;
          desktop = 11;
        };
      };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      opacity = {
        terminal = 1.0;
        popups = 0.95;
      };
    };
  };

  # ── Darwin Styling (System-level) ─────────────────────────────
  flake.modules.darwin.styling = {
    pkgs,
    inputs,
    lib,
    ...
  }: {
    imports = [
      inputs.stylix.darwinModules.stylix
      ./theme.nix
    ];

    stylix = {
      enable = true;
      enableReleaseChecks = false;
      polarity = "dark";

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

    # Explicitly add fonts to system-wide packages for Darwin
    fonts.packages = [ 
      pkgs.maple-mono.NF 
      pkgs.inter
      pkgs.noto-fonts
    ];
  };

  # ── Home Manager Styling ──────────────────────────────────────
  flake.modules.homeManager.styling = {
    pkgs,
    lib,
    config,
    inputs,
    ...
  }: let 
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  in {
    imports = [inputs.stylix.homeManagerModules.stylix];
    config = {
      stylix = {
        # We only need to define targets here; the base theme is inherited from system
        enable = true;
        
        targets.vscode.enable = true;
        targets.ghostty.enable = true;
        # targets.bat.enable = true;
        # targets.fzf.enable = true;
        # targets.lsd.enable = true;
        # targets.btop.enable = true;
        # targets.vesktop.enable = true;
        targets.spicetify.enable = true;
        targets.qt.enable = false;
      };

      # ── Stylix-Themed LibreWolf UI ──────────────────────────────
      programs.librewolf.profiles = let 
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
            --toolbar-field-background-color: var(--base01) !important;
            --toolbar-field-color: var(--base05) !important;
            --toolbar-field-border-color: var(--base03) !important;
            --toolbar-field-focus-background-color: var(--base01) !important;
            --toolbar-field-focus-color: var(--base05) !important;
            --toolbar-field-focus-border-color: var(--base0D) !important;
            --lwt-selected-tab-background-color: var(--base02) !important;
            --lwt-tab-text-color: var(--base05) !important;
            --lwt-background-tab-text-color: var(--base04) !important;
          }

          #nav-bar, #TabsToolbar, #PersonalToolbar, #navigator-toolbox, #sidebar-box, #sidebar-header {
            background-color: var(--base00) !important;
            background-image: none !important;
            color: var(--base05) !important;
            border: none !important;
            box-shadow: none !important;
          }

          /* Tab Bar Tweaks */
          .tab-background[selected="true"] {
            background-color: var(--base02) !important;
            background-image: none !important;
          }

          .tab-line[selected="true"] {
            background-color: var(--base0D) !important;
          }

          /* Context Menus */
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
          /* Internal Pages Theme */
          @-moz-document url-prefix(about:), url-prefix(chrome:) {
            :root {
              --in-content-page-background: var(--base00) !important;
              --in-content-page-color: var(--base05) !important;
              --in-content-box-background: var(--base01) !important;
              --in-content-primary-button-background: var(--base0D) !important;
            }
            body {
              background-color: var(--base00) !important;
              color: var(--base05) !important;
            }
          }
        '';
      in {
        default = {
          userChrome = stylixUserChrome;
          userContent = stylixUserContent;
        };
        default-release = {
          userChrome = stylixUserChrome;
          userContent = stylixUserContent;
        };
      };

      # ── GTK Theming ─────────────────────────────────────────────
      gtk = {
        gtk4.theme = lib.mkForce null; # Silence evaluation warning on all platforms
        enable = lib.mkDefault (!isDarwin);
        gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
      };

      # ── Qt Theming (Linux only) ─────────────────────────────────
      qt = lib.mkIf (!isDarwin) {
        enable = true;
        platformTheme.name = lib.mkForce "gtk3";
      };

      # ── Terminal env ────────────────────────────────────────────
      programs.zsh.initContent = ''
        export COLORTERM=truecolor
      '';
    };
  };
}
