{
  flake.modules.homeManager.ghostty = { pkgs, lib, config, ... }: {
    options.dendritic.apps.ghostty = {
      enable = lib.mkEnableOption "Ghostty terminal emulator";
      fontSize = lib.mkOption {
        type = lib.types.int;
        default = config.stylix.fonts.sizes.terminal;
        description = "Font size for Ghostty.";
      };
    };

    config = lib.mkIf config.dendritic.apps.ghostty.enable {
      programs.ghostty = {
        enable = true;
        # Automatically select the correct package for the platform
        package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        
        settings = {
          font-size = config.dendritic.apps.ghostty.fontSize;
          window-decoration = true;
          macos-option-as-alt = true;
          shell-integration = "detect";
          # Use absolute path for zsh to ensure it launches correctly on macOS
          command = "${pkgs.zsh}/bin/zsh";

          # Manually inherit colors from Stylix
          background = "#${config.lib.stylix.colors.base00}";
          foreground = "#${config.lib.stylix.colors.base05}";
          cursor-color = "#${config.lib.stylix.colors.base05}";
          selection-background = "#${config.lib.stylix.colors.base02}";
          selection-foreground = "#${config.lib.stylix.colors.base05}";

          palette = [
            "0=#${config.lib.stylix.colors.base00}"
            "1=#${config.lib.stylix.colors.base08}"
            "2=#${config.lib.stylix.colors.base0B}"
            "3=#${config.lib.stylix.colors.base0A}"
            "4=#${config.lib.stylix.colors.base0D}"
            "5=#${config.lib.stylix.colors.base0E}"
            "6=#${config.lib.stylix.colors.base0C}"
            "7=#${config.lib.stylix.colors.base05}"
            "8=#${config.lib.stylix.colors.base03}"
            "9=#${config.lib.stylix.colors.base08}"
            "10=#${config.lib.stylix.colors.base0B}"
            "11=#${config.lib.stylix.colors.base0A}"
            "12=#${config.lib.stylix.colors.base0D}"
            "13=#${config.lib.stylix.colors.base0E}"
            "14=#${config.lib.stylix.colors.base0C}"
            "15=#${config.lib.stylix.colors.base07}"
          ];
        };
      };

      home.packages = [ config.programs.ghostty.package ];
    };
  };
}
