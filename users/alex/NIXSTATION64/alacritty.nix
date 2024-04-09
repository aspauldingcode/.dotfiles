{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    #ueberzug
    ueberzugpp # required for yazi Window System Protocol to preview images.
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 0;
        padding.y = 10;
        opacity = 0.9;
        class.instance = "Alacritty";
        class.general = "Alacritty";
        decorations = "None";
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = {
          family = "Hack Nerd Font Mono";
          style = "Regular";
        };
        bold = {
          family = "Hack Nerd Font Mono";
          style = "Bold";
        };
        italic = {
          family = "Hack Nerd Font Mono";
          style = "Italic";
        };
        size = 9.0;
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
        normal = {
          # TRYING TO GRUVBOX IT
          black = "#${config.colorScheme.colors.base00}";
          red = "#${config.colorScheme.colors.base08}";
          green = "#${config.colorScheme.colors.base0B}";
          yellow = "#${config.colorScheme.colors.base0A}";
          blue = "#${config.colorScheme.colors.base0D}";
          # purple  ="#${config.colorScheme.colors.base0E}";
          # aqua    ="#${config.colorScheme.colors.base0C}";
          # gray    ="#${config.colorScheme.colors.base05}";
        };
        bright = {
          black = "#${config.colorScheme.colors.base03}";
          red = "#${config.colorScheme.colors.base08}";
          green = "#${config.colorScheme.colors.base0B}";
          yellow = "#${config.colorScheme.colors.base0A}";
          blue = "#${config.colorScheme.colors.base0D}";
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

      selection = {
        save_to_clipboard = true; # copy on selection
      };

      keyboard.bindings = [
        {
          key = "C";
          mods = "Control";
          action = "Copy";
        }
        {
          key = "C";
          mods = "Shift|Control";
          action = "ReceiveChar";
        }
        # {
        #   key = "f";
        #   mods = "Shift|Control";
        #   action = "";
        # }
        {
          key = "V";
          mods = "Control";
          action = "Paste";
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
