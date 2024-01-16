{ config, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 0;
        padding.y = 10;
        opacity   = 0.9;
        blur = true;
        class.instance = "Alacritty";
        class.general  = "Alacritty";
        decorations = "Buttonless";
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono";
          style = "Italic";
        };
        size = 12.0;
      };

        # Becomes either 'dark' or 'light', based on your colors! (in qutebrowser)
        #webppage.preferred_color_scheme = "${config.colorScheme.kind}";

        colors = {
          primary = {
            foreground = "#${config.colorScheme.colors.base05}";
            background = "#${config.colorScheme.colors.base00}";
          };
        #cursor = {
        #text    ="0xEBEBEB";
        #cursor  ="0xEBEBEB";
        #};
        normal = {#TRYING TO GRUVBOX IT
        black   ="#${config.colorScheme.colors.base00}";
        red     ="#${config.colorScheme.colors.base08}";
        green   ="#${config.colorScheme.colors.base0B}";
        yellow  ="#${config.colorScheme.colors.base0A}";
        blue    ="#${config.colorScheme.colors.base0D}";
          # purple  ="#${config.colorScheme.colors.base0E}";
          # aqua    ="#${config.colorScheme.colors.base0C}";
          # gray    ="#${config.colorScheme.colors.base05}";
        };
        bright = {
          black   ="#${config.colorScheme.colors.base03}";
          red     ="#${config.colorScheme.colors.base08}";
          green   ="#${config.colorScheme.colors.base0B}";
          yellow  ="#${config.colorScheme.colors.base0A}";
          blue    ="#${config.colorScheme.colors.base0D}";
          # purple  ="#${config.colorScheme.colors.base0E}";
          # aqua    ="#${config.colorScheme.colors.base0C}";
          # gray    ="#${config.colorScheme.colors.base07}";
        };
        draw_bold_text_with_bright_colors = true;
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 750;
      };
      live_config_reload = true;

      keyboard.bindings = [
        {
          key = "F";
          mods = "Command|Shift";
          action = "ToggleSimpleFullscreen";
        }
        {
          key = "C";
          mods = "Command";
          action = "Copy";
        }
        {
          key = "C";
          mods = "Command|Shift";
          action = "Copy";
        }
        {
          key = "PageUp";
          mode = "~Alt";
          action = "ScrollPageUp";
        }
        { 
          key = "PageDown";
          mode = "~Alt";
          action = "ScrollPageDown";
        }
      ];
    };
  };
}
