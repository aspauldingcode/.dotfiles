{ config, ... }:
let
  inherit (config.colorScheme) palette;
in
{
  programs.qutebrowser = {
    enable = false;
    settings.colors = {
      # Becomes either 'dark' or 'light', based on your colors!
      webppage.preferred_color_scheme = "${config.colorScheme.variant}";
      tabs.bar.bg = "#${palette.base00}";
      keyhint.fg = "#${palette.base05}";
      # ...
    };
  };
}
