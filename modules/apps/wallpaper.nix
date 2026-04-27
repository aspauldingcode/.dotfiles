{
  # ── All-In Wallpaper Module (Dendritic) ──────────────────────
  #
  # Features:
  # 1. Custom Wallpaper Database: Automatically discovered from ./wallpapers/
  # 2. Stylix Integration: Colorscheme propagation from base16 to gowall.
  # 3. Gowall Pipeline: Auto-colorization to match the current system theme.
  # 4. Declarative macOS: Using macos-wallpaper CLI tool.
  # 5. Declarative Linux: Using wpaperd (daemon with TOML config).
  #
  flake.modules.homeManager.wallpaper = { pkgs, lib, config, ... }:
  let
    cfg = config.dendritic.wallpaper;
    isDarwin = pkgs.stdenv.isDarwin;

    # ── Database Resolution ──────────────────────────────────────
    rawImage = if builtins.hasAttr cfg.selected cfg.database 
               then cfg.database."${cfg.selected}"
               else cfg.path;

    # ── Stylix Theme Extraction ──────────────────────────────────
    stylixTheme = if config.stylix.base16Scheme != null then
      lib.removeSuffix ".yaml" (builtins.baseNameOf config.stylix.base16Scheme)
    else "catppuccin";

    gowallTheme = if cfg.gowall.theme != "" then cfg.gowall.theme else (
      if lib.hasPrefix "catppuccin" stylixTheme then "catppuccin"
      else if lib.hasPrefix "nord" stylixTheme then "nord"
      else if lib.hasPrefix "dracula" stylixTheme then "dracula"
      else if lib.hasPrefix "everforest" stylixTheme then "everforest"
      else "catppuccin"
    );

    # ── Gowall Pipeline ──────────────────────────────────────────
    processedImage = if cfg.gowall.enable then
      pkgs.runCommand "processed-wallpaper-${cfg.selected}.png" {
        nativeBuildInputs = [ pkgs.gowall ];
      } ''
        export HOME=$TMPDIR
        ${pkgs.gowall}/bin/gowall convert "${rawImage}" -t "${gowallTheme}" --output "$out"
      ''
    else
      rawImage;
  in
  {
    options.dendritic.wallpaper = {
      enable = lib.mkEnableOption "Advanced declarative wallpaper management";
      
      database = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = 
          let
            dir = ../../wallpapers;
            files = if builtins.pathExists dir then builtins.readDir dir else {};
            isImage = name: lib.any (ext: lib.hasSuffix ext name) [ ".png" ".jpg" ".jpeg" ".webp" ];
            images = lib.filterAttrs (name: type: type == "regular" && isImage name) files;
          in
          (lib.mapAttrs' (name: _: {
            name = lib.removeSuffix ".webp" (lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" name)));
            value = dir + "/${name}";
          }) images) // {
            "nix-dark" = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-dark-gray.png";
              sha256 = "sha256-JaLHdBxwrphKVherDVe5fgh+3zqUtpcwuNbjwrBlAok=";
            };
          };
        description = "Automated wallpaper database from /wallpapers directory.";
      };

      selected = lib.mkOption {
        type = lib.types.str;
        default = "mountain-sunset";
        description = "Selected wallpaper from the database.";
      };

      path = lib.mkOption {
        type = lib.types.path;
        default = ../../wallpapers/mountain-sunset.png;
        description = "Manual path fallback.";
      };

      scale = lib.mkOption {
        type = lib.types.enum [ "fill" "fit" "stretch" "center" ];
        default = "fill";
        description = "Scaling mode.";
      };

      gowall = {
        enable = lib.mkEnableOption "Enable gowall colorization";
        theme = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Gowall theme override.";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      # ── Stylix Integration ──────────────────────────────────────
      # Disable palette generation when cross-compiling or emulating (like ARM on x86 CI)
      # building Haskell (palette-generator) in QEMU is extremely flaky and slow.
      stylix.image = lib.mkForce (
        if (pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system && pkgs.stdenv.hostPlatform.isAarch64) 
        then null 
        else processedImage
      );

      # ── Packages ────────────────────────────────────────────────
      home.packages = [ pkgs.gowall ] 
        ++ lib.optionals isDarwin [ pkgs.macos-wallpaper ]
        ++ lib.optionals (!isDarwin) [ pkgs.wpaperd ];

      # ── macOS Implementation ────────────────────────────────────
      home.activation.setWallpaper = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
        WALLPAPER_BIN="${pkgs.macos-wallpaper}/bin/wallpaper"
        if [ -x "$WALLPAPER_BIN" ]; then
          echo "Setting macOS wallpaper: ${processedImage}"
          $DRY_RUN_CMD "$WALLPAPER_BIN" set "${processedImage}" --scale ${cfg.scale}
        fi
      '');

      # ── Linux Implementation (wpaperd) ──────────────────────────
      # wpaperd is highly declarative via its TOML config.
      xdg.configFile."wpaperd/wallpaper.toml" = lib.mkIf (!isDarwin) {
        text = ''
          [*]
          path = "${processedImage}"
          apply-to = ["*"]
          mode = "${cfg.scale}"
        '';
      };

      # Autostart wpaperd on Wayland/Sway
      wayland.windowManager.sway.config.startup = lib.mkIf (!isDarwin) [
        { command = "${pkgs.wpaperd}/bin/wpaperd"; always = true; }
      ];

      # Ensure Sway background is NOT set by Sway itself to avoid conflicts
      wayland.windowManager.sway.config.output."*".bg = lib.mkForce "none";
    };
  };

  # ── System Modules ───────────────────────────────────────────
  flake.modules.darwin.wallpaper = { pkgs, lib, config, ... }: {
    options.dendritic.wallpaper.enable = lib.mkEnableOption "Wallpaper management";
  };
  flake.modules.nixos.wallpaper = { pkgs, lib, config, ... }: {
    options.dendritic.wallpaper.enable = lib.mkEnableOption "Wallpaper management";
  };
}
