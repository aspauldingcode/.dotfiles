{
  # ── NixOS Styling ─────────────────────────────────────────────
  flake.modules.nixos.styling = {
    pkgs,
    inputs,
    lib,
    ...
  }: {
    imports = [inputs.stylix.nixosModules.stylix];

    stylix = {
      enable = true;
      polarity = "dark";
      # Image is now handled by dendritic.wallpaper

      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.monaspace;
          name = "MonaspiceNe Nerd Font Mono";
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

    # Light mode specialisation for NixOS
    specialisation.light.configuration = {
      stylix.polarity = lib.mkForce "light";
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    };
  };

  # ── Darwin Styling ────────────────────────────────────────────
  flake.modules.darwin.styling = {
    pkgs,
    inputs,
    lib,
    ...
  }: {
    imports = [inputs.stylix.darwinModules.stylix];

    stylix = {
      enable = true;
      polarity = "dark";
      # Image is now handled by dendritic.wallpaper

      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.monaspace;
          name = "MonaspiceNe Nerd Font Mono";
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
          terminal = 14;
          applications = 14;
        };
      };

      opacity = {
        terminal = 1.0;
        popups = 0.95;
      };
    };

    # macOS wallpaper management moved to modules/apps/wallpaper.nix
  };

  # ── Home Manager Styling ──────────────────────────────────────
  flake.modules.homeManager.styling = {
    pkgs,
    inputs,
    lib,
    config,
    ...
  }: let
    isDarwin = pkgs.stdenv.isDarwin;
  in {
    stylix.enable = true;

    # ── Wallpaper Configuration ──────────────────────────────────
    dendritic.wallpaper = {
      enable = true;
      selected = "mountain-sunset";
      gowall = {
        enable = true;
        theme = "catppuccin"; # Matches our base16 scheme
      };
    };

    # ── Stylix Targets ──────────────────────────────────────────
    # Let Stylix theme everything it can
    stylix.targets.xresources.enable = lib.mkForce (!isDarwin);
    stylix.targets.vim.enable = false; # nixvim uses its own module
    stylix.targets.nixvim.enable = false; # Stylix generates require() before plugins load
    stylix.targets.vscode.enable = true;
    stylix.targets.ghostty.enable = true;
    stylix.targets.zen-browser.profileNames = ["default"];
    # ghostty target is ENABLED (stylix injects palette automatically)
    # gtk target is ENABLED by default
    # qt target is ENABLED by default

    # ── GTK Theming (Linux only) ────────────────────────────────
    gtk = lib.mkMerge [
      {gtk4.theme = null;} # Silence GTK4 evaluation warning on all platforms
      (lib.mkIf (!isDarwin) {
        enable = true;
      })
    ];

    # ── Qt Theming (Linux only — macOS uses native Cocoa) ─────
    qt = lib.mkIf (!isDarwin) {
      enable = true;
      platformTheme.name = lib.mkForce "gtk3";
    };

    # ── Terminal env ────────────────────────────────────────────
    programs.zsh.envExtra = ''
      export COLORTERM=truecolor
    '';
  };
}
