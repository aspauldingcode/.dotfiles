{ config, pkgs, ... }:

let
  inherit (config.colorScheme) palette;
  fontSize = if pkgs.stdenv.isDarwin then 12.5 else 9.0;
in
{
  home.packages = with pkgs; [
    # ueberzug
    # ueberzugpp # required for yazi Window System Protocol to preview images.
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
        padding.x = 0;
        #padding.y = 10; # pretty lavat
        opacity = 1.0; # use 0.9
        blur = false; # use jankyborders with blur instead
        class.instance = "Alacritty";
        class.general = "Alacritty";
        decorations = "Transparent"; # "Full" | "None" | "Transparent" | "Buttonless"
        option_as_alt = "Both";
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
        size = fontSize;
        offset = {
          x = 0;
          y = 0;
        };
        glyph_offset = {
          x = 0;
          y = 0;
        };
        # use_thin_strokes = true;  # Enable this to make the fonts thinner
      };

      # dpi = {
      #   x = 96;  # Adjust according to your screen's DPI, common values are 96, 110, 120
      #   y = 96;
      # };

      # Enable hinting and antialiasing
      # hinting = "slight";  # Options: none, slight, medium, full
      # antialiasing = "subpixel";  # Options: none, grayscale, subpixel

      # Becomes either 'dark' or 'light', based on your colors! (in qutebrowser)
      #webppage.preferred_color_scheme = "${kind}";

      colors = {
        draw_bold_text_with_bright_colors = false;

        primary = {
          background = "#${palette.base00}";
          foreground = "#${palette.base05}";
        };

        cursor = {
          text = "#${palette.base00}";
          cursor = "#${palette.base05}";
        };

        normal = {
          black = "#${palette.base00}";
          red = "#${palette.base08}";
          green = "#${palette.base0B}";
          yellow = "#${palette.base0A}";
          blue = "#${palette.base0D}";
          magenta = "#${palette.base0E}";
          cyan = "#${palette.base0C}";
          white = "#${palette.base05}";
        };

        bright = {
          black = "#${palette.base03}";
          red = "#${palette.base08}";
          green = "#${palette.base0B}";
          yellow = "#${palette.base0A}";
          blue = "#${palette.base0D}";
          magenta = "#${palette.base0E}";
          cyan = "#${palette.base0C}";
          white = "#${palette.base07}";
        };

        indexed_colors = [
          {
            index = 16;
            color = "#${palette.base09}";
          }
          {
            index = 17;
            color = "#${palette.base0F}";
          }
          {
            index = 18;
            color = "#${palette.base01}";
          }
          {
            index = 19;
            color = "#${palette.base02}";
          }
          {
            index = 20;
            color = "#${palette.base04}";
          }
          {
            index = 21;
            color = "#${palette.base06}";
          }
        ];
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 750;
      };
      general = {
        live_config_reload = true;
      };

      selection = {
        save_to_clipboard = true; # copy on selection
      };

      keyboard.bindings = [
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
        {
          key = "+";
          mods = "Control";
          action = "IncreaseFontSize";
        }
        {
          key = "-";
          mods = "Control";
          action = "DecreaseFontSize";
        }
        {
          key = "B";
          mods = "Command|Shift";
          chars = "\x1b[66;5u";
        }
        {
          key = "B";
          mods = "Command";
          chars = "\x1b[66;4u";
        }
        {
          key = "B";
          mods = "Control|Shift";
          chars = "\x1b[66;5u";
        }
        {
          key = "B";
          mods = "Control";
          chars = "\x1b[66;5u";
        }
        {
          key = "Enter";
          mods = "Alt|Shift";
          action = "SpawnNewInstance";
        }
        {
          key = "Enter";
          mods = "Alt";
          action = "CreateNewWindow";
        }
      ];
    };
  };
}
