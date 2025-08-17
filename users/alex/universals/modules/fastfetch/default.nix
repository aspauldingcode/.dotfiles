{
  config,
  pkgs,
  nix-colors,
  ...
}:
{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        padding = {
          top = 2;
        };
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "bios"
        "bootmgr"
        "board"
        # "chassis" # didn't work
        "kernel"
        # "initsystem" # didn't work
        "uptime"
        "loadavg"
        "processes"
        {
          type = "packages";
          format = "{1} (nix-system), {2} (nix-default), {3} (brew), {4} (brew-cask)";
        }
        "shell"
        "editor"
        "display"
        "brightness"
        #   "monitor"
        # "lm"
        "de"
        {
          type = "wm";
          format = "Yabai";
        }
        {
          type = "theme";
          themeText = "${config.colorScheme.slug} (${config.colorScheme.variant})";
        }
        #   "icons"
        #   "font"
        {
          type = "cursor";
          format = "Bibata-Modern-Ice";
        }
        "colors"
      ];
    };
  };
}
