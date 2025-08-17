{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorScheme) palette;
in
{
  config = {
    programs.nushell = {
      extraConfig = ''
        def start_zellij [] {
          if 'ZELLIJ' not-in ($env | columns) {
            # Only start zellij if we're in an SSH session
            if ('SSH_CLIENT' in ($env | columns)) or ('SSH_TTY' in ($env | columns)) or ('SSH_CONNECTION' in ($env | columns)) {
              if 'ZELLIJ_AUTO_ATTACH' in ($env | columns) and $env.ZELLIJ_AUTO_ATTACH == 'true' {
                zellij attach -c
              } else {
                zellij
              }

              if 'ZELLIJ_AUTO_EXIT' in ($env | columns) and $env.ZELLIJ_AUTO_EXIT == 'true' {
                exit
              }
            }
          }
        }
      '';

      extraLogin = ''
        start_zellij
      '';
    };
    programs.zellij = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
      settings = {
        theme = "custom";
        themes = {
          custom = {
            fg = "#${palette.base05}";
            bg = "#${palette.base02}";
            black = "#${palette.base00}";
            red = "#${palette.base08}";
            green = "#${palette.base0B}";
            yellow = "#${palette.base0A}";
            blue = "#${palette.base0D}";
            magenta = "#${palette.base0E}";
            cyan = "#${palette.base0C}";
            white = "#${palette.base05}";
            orange = "#${palette.base09}";
          };
        };
      };
    };
  };
}
