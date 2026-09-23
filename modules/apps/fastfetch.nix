{
  flake.modules.homeManager.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      c = config.lib.stylix.colors.withHashtag;
    in
    {
      # Seed; dendritic-appearance overwrites from ~/.colors.toml on light/dark.
      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            type = "auto";
            padding = {
              top = 1;
              left = 1;
              right = 2;
            };
            color = {
              "1" = c.base0D;
              "2" = c.base0E;
              "3" = c.base0C;
              "4" = c.base0B;
              "5" = c.base0A;
              "6" = c.base08;
              "7" = c.base05;
              "8" = c.base00;
              "9" = c.base0D;
            };
          };
          display = {
            separator = "  ";
            color = {
              keys = c.base0D;
              title = c.base0E;
              output = c.base05;
              separator = c.base03;
            };
          };
          modules = [
            "title"
            "separator"
            "os"
            "host"
            "kernel"
            "uptime"
            "packages"
            "shell"
            "terminal"
            "cpu"
            "memory"
            "disk"
            "break"
            "colors"
          ];
        };
      };

      # Live writer replaces the HM file; clear before link checks.
      home.activation.dendriticClearLiveFastfetch = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        $DRY_RUN_CMD rm -f "${config.xdg.configHome}/fastfetch/config.jsonc"
      '';
    };
}
