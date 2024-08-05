{ config, ... }:
let
   inherit (config.colorScheme) colors;
in
{
    programs.qutebrowser = {
      enable = false;
      settings.colors = {
        # Becomes either 'dark' or 'light', based on your colors!
        webppage.preferred_color_scheme = "${config.colorScheme.variant}";
        tabs.bar.bg = "#${config.colorScheme.palette.base00}";
        keyhint.fg = "#${config.colorScheme.palette.base05}";
        # ...
      };
    };
}
