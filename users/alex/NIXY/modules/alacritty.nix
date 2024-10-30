{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
in
{
  home.packages = with pkgs; [
    #ueberzug
    ueberzugpp # required for yazi Window System Protocol to preview images.
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
        decorations = "None"; # "Full" | "None" | "Transparent" | "Buttonless"
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
        size = 12.5; # Slightly larger to reduce blurriness
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
        primary = {
          foreground = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
          background = "#${colors.base00}"; # Default Background

          dim_foreground = "#${colors.base01}"; # Lighter Background (Used for status bars, line number and folding marks)
          bright_foreground = "#${colors.base06}"; # Light Foreground (Not often used)
        };

        cursor = {
          text = "#${colors.base00}"; # Default Background
          cursor = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
        };

        vi_mode_cursor = {
          text = "#${colors.base00}"; # Default Background
          cursor = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
        };

        search = {
          matches = {
            foreground = "#${colors.base00}"; # Default Background
            background = "#${colors.base08}"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          };
          focused_match = {
            foreground = "#${colors.base00}"; # Default Background
            background = "#${colors.base0A}"; # Classes, Markup Bold, Search Text Background
          };
        };

        hints = {
          start = {
            foreground = "#${colors.base00}"; # Default Background
            background = "#${colors.base0A}"; # Classes, Markup Bold, Search Text Background
          };
          end = {
            foreground = "#${colors.base00}"; # Default Background
            background = "#${colors.base08}"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          };
        };

        line_indicator = {
          foreground = "None"; # Uses opposing primary color
          background = "None"; # Uses opposing primary color
        };

        footer_bar = {
          foreground = "#${colors.base00}"; # Default Background
          background = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
        };

        selection = {
          text = "#${colors.base08}"; # Default Background
          background = "#${colors.base02}"; # Default Foreground, Caret, Delimiters, Operators
        };

        normal = {
          black = "#${colors.base00}"; # Default Background
          red = "#${colors.base08}"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          green = "#${colors.base0B}"; # Strings, Inherited Class, Markup Code, Diff Inserted
          yellow = "#${colors.base0A}"; # Classes, Markup Bold, Search Text Background
          blue = "#${colors.base0D}"; # Functions, Methods, Attribute IDs, Headings
          magenta = "#${colors.base0E}"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          cyan = "#${colors.base0C}"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          white = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
        };

        bright = {
          black = "#${colors.base03}"; # Comments, Invisibles, Line Highlighting
          red = "#${colors.base08}"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
          green = "#${colors.base0B}"; # Strings, Inherited Class, Markup Code, Diff Inserted
          yellow = "#${colors.base0A}"; # Classes, Markup Bold, Search Text Background
          blue = "#${colors.base0D}"; # Functions, Methods, Attribute IDs, Headings
          magenta = "#${colors.base0E}"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          cyan = "#${colors.base0C}"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          white = "#${colors.base07}"; # Light Background (Not often used)
        };

        dim = {
          black = "#${colors.base01}"; # Lighter Background (Used for status bars, line number and folding marks)
          red = "#${colors.base02}"; # Selection Background
          green = "#${colors.base03}"; # Comments, Invisibles, Line Highlighting
          yellow = "#${colors.base04}"; # Dark Foreground (Used for status bars)
          blue = "#${colors.base05}"; # Default Foreground, Caret, Delimiters, Operators
          magenta = "#${colors.base06}"; # Light Foreground (Not often used)
          cyan = "#${colors.base07}"; # Light Background (Not often used)
          white = "#${colors.base08}"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
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

      #   # Command + Shift bindings
# -- 5 is the sum of bits for the ctrl and shift modifiers (1 is shift, 2 is alt, 4 is ctrl);
      # chars: "\x1b[74;5u" 
      #   {
      #     key = "A";
      #     mods = "Command|Shift";
      #     chars = "\x1b[65;5u";
      #   }
        {
          key = "B";
          mods = "Command|Shift";
          chars = "\x1b[66;5u";
        }
      #   {
      #     key = "C";
      #     mods = "Command|Shift";
      #     chars = "\x1b[67;5u";
      #   }
      #   {
      #     key = "D";
      #     mods = "Command|Shift";
      #     chars = "\x1b[68;5u";
      #   }
      #   {
      #     key = "E";
      #     mods = "Command|Shift";
      #     chars = "\x1b[69;5u";
      #   }
      #   {
      #     key = "F";
      #     mods = "Command|Shift";
      #     chars = "\x1b[70;5u";
      #   }
      #   {
      #     key = "G";
      #     mods = "Command|Shift";
      #     chars = "\x1b[71;5u";
      #   }
      #   {
      #     key = "H";
      #     mods = "Command|Shift";
      #     chars = "\x1b[72;5u";
      #   }
      #   {
      #     key = "I";
      #     mods = "Command|Shift";
      #     chars = "\x1b[73;5u";
      #   }
      #   {
      #     key = "J";
      #     mods = "Command|Shift";
      #     chars = "\x1b[74;5u";
      #   }
      #   {
      #     key = "K";
      #     mods = "Command|Shift";
      #     chars = "\x1b[75;5u";
      #   }
      #   {
      #     key = "L";
      #     mods = "Command|Shift";
      #     chars = "\x1b[76;5u";
      #   }
      #   {
      #     key = "M";
      #     mods = "Command|Shift";
      #     chars = "\x1b[77;5u";
      #   }
      #   {
      #     key = "N";
      #     mods = "Command|Shift";
      #     chars = "\x1b[78;5u";
      #   }
      #   {
      #     key = "O";
      #     mods = "Command|Shift";
      #     chars = "\x1b[79;5u";
      #   }
      #   {
      #     key = "P";
      #     mods = "Command|Shift";
      #     chars = "\x1b[80;5u";
      #   }
      #   {
      #     key = "Q";
      #     mods = "Command|Shift";
      #     chars = "\x1b[81;5u";
      #   }
      #   {
      #     key = "R";
      #     mods = "Command|Shift";
      #     chars = "\x1b[82;5u";
      #   }
      #   {
      #     key = "S";
      #     mods = "Command|Shift";
      #     chars = "\x1b[83;5u";
      #   }
      #   {
      #     key = "T";
      #     mods = "Command|Shift";
      #     chars = "\x1b[84;5u";
      #   }
      #   {
      #     key = "U";
      #     mods = "Command|Shift";
      #     chars = "\x1b[85;5u";
      #   }
      #   {
      #     key = "V";
      #     mods = "Command|Shift";
      #     chars = "\x1b[86;5u";
      #   }
      #   {
      #     key = "W";
      #     mods = "Command|Shift";
      #     chars = "\x1b[87;5u";
      #   }
      #   {
      #     key = "X";
      #     mods = "Command|Shift";
      #     chars = "\x1b[88;5u";
      #   }
      #   {
      #     key = "Y";
      #     mods = "Command|Shift";
      #     chars = "\x1b[89;5u";
      #   }
      #   {
      #     key = "Z";
      #     mods = "Command|Shift";
      #     chars = "\x1b[90;5u";
      #   }

      #   # Command bindings
      #   {
      #     key = "A";
      #     mods = "Command";
      #     chars = "\x1b[65;5u";
      #   }
        {
          key = "B";
          mods = "Command";
          chars = "\x1b[66;4u";
        }
      #   {
      #     key = "C";
      #     mods = "Command";
      #     chars = "\x1b[67;5u";
      #   }
      #   {
      #     key = "D";
      #     mods = "Command";
      #     chars = "\x1b[68;5u";
      #   }
      #   {
      #     key = "E";
      #     mods = "Command";
      #     chars = "\x1b[69;5u";
      #   }
      #   {
      #     key = "F";
      #     mods = "Command";
      #     chars = "\x1b[70;5u";
      #   }
      #   {
      #     key = "G";
      #     mods = "Command";
      #     chars = "\x1b[71;5u";
      #   }
      #   {
      #     key = "H";
      #     mods = "Command";
      #     chars = "\x1b[72;5u";
      #   }
      #   {
      #     key = "I";
      #     mods = "Command";
      #     chars = "\x1b[73;5u";
      #   }
      #   {
      #     key = "J";
      #     mods = "Command";
      #     chars = "\x1b[74;5u";
      #   }
      #   {
      #     key = "K";
      #     mods = "Command";
      #     chars = "\x1b[75;5u";
      #   }
      #   {
      #     key = "L";
      #     mods = "Command";
      #     chars = "\x1b[76;5u";
      #   }
      #   {
      #     key = "M";
      #     mods = "Command";
      #     chars = "\x1b[77;5u";
      #   }
      #   {
      #     key = "N";
      #     mods = "Command";
      #     chars = "\x1b[78;5u";
      #   }
      #   {
      #     key = "O";
      #     mods = "Command";
      #     chars = "\x1b[79;5u";
      #   }
      #   {
      #     key = "P";
      #     mods = "Command";
      #     chars = "\x1b[80;5u";
      #   }
      #   {
      #     key = "Q";
      #     mods = "Command";
      #     chars = "\x1b[81;5u";
      #   }
      #   {
      #     key = "R";
      #     mods = "Command";
      #     chars = "\x1b[82;5u";
      #   }
      #   {
      #     key = "S";
      #     mods = "Command";
      #     chars = "\x1b[83;5u";
      #   }
      #   {
      #     key = "T";
      #     mods = "Command";
      #     chars = "\x1b[84;5u";
      #   }
      #   {
      #     key = "U";
      #     mods = "Command";
      #     chars = "\x1b[85;5u";
      #   }
      #   {
      #     key = "V";
      #     mods = "Command";
      #     chars = "\x1b[86;5u";
      #   }
      #   {
      #     key = "W";
      #     mods = "Command";
      #     chars = "\x1b[87;5u";
      #   }
      #   {
      #     key = "X";
      #     mods = "Command";
      #     chars = "\x1b[88;5u";
      #   }
      #   {
      #     key = "Y";
      #     mods = "Command";
      #     chars = "\x1b[89;5u";
      #   }
      #   {
      #     key = "Z";
      #     mods = "Command";
      #     chars = "\x1b[90;5u";
      #   }

      #   # Control + Shift bindings
      #   {
      #     key = "A";
      #     mods = "Control|Shift";
      #     chars = "\x1b[65;5u";
      #   }
        {
          key = "B";
          mods = "Control|Shift";
          chars = "\x1b[66;5u";
        }
      #   {
      #     key = "C";
      #     mods = "Control|Shift";
      #     chars = "\x1b[67;5u";
      #   }
      #   {
      #     key = "D";
      #     mods = "Control|Shift";
      #     chars = "\x1b[68;5u";
      #   }
      #   {
      #     key = "E";
      #     mods = "Control|Shift";
      #     chars = "\x1b[69;5u";
      #   }
      #   {
      #     key = "F";
      #     mods = "Control|Shift";
      #     chars = "\x1b[70;5u";
      #   }
      #   {
      #     key = "G";
      #     mods = "Control|Shift";
      #     chars = "\x1b[71;5u";
      #   }
      #   {
      #     key = "H";
      #     mods = "Control|Shift";
      #     chars = "\x1b[72;5u";
      #   }
      #   {
      #     key = "I";
      #     mods = "Control|Shift";
      #     chars = "\x1b[73;5u";
      #   }
      #   {
      #     key = "J";
      #     mods = "Control|Shift";
      #     chars = "\x1b[74;5u";
      #   }
      #   {
      #     key = "K";
      #     mods = "Control|Shift";
      #     chars = "\x1b[75;5u";
      #   }
      #   {
      #     key = "L";
      #     mods = "Control|Shift";
      #     chars = "\x1b[76;5u";
      #   }
      #   {
      #     key = "M";
      #     mods = "Control|Shift";
      #     chars = "\x1b[77;5u";
      #   }
      #   {
      #     key = "N";
      #     mods = "Control|Shift";
      #     chars = "\x1b[78;5u";
      #   }
      #   {
      #     key = "O";
      #     mods = "Control|Shift";
      #     chars = "\x1b[79;5u";
      #   }
      #   {
      #     key = "P";
      #     mods = "Control|Shift";
      #     chars = "\x1b[80;5u";
      #   }
      #   {
      #     key = "Q";
      #     mods = "Control|Shift";
      #     chars = "\x1b[81;5u";
      #   }
      #   {
      #     key = "R";
      #     mods = "Control|Shift";
      #     chars = "\x1b[82;5u";
      #   }
      #   {
      #     key = "S";
      #     mods = "Control|Shift";
      #     chars = "\x1b[83;5u";
      #   }
      #   {
      #     key = "T";
      #     mods = "Control|Shift";
      #     chars = "\x1b[84;5u";
      #   }
      #   {
      #     key = "U";
      #     mods = "Control|Shift";
      #     chars = "\x1b[85;5u";
      #   }
      #   {
      #     key = "V";
      #     mods = "Control|Shift";
      #     chars = "\x1b[86;5u";
      #   }
      #   {
      #     key = "W";
      #     mods = "Control|Shift";
      #     chars = "\x1b[87;5u";
      #   }
      #   {
      #     key = "X";
      #     mods = "Control|Shift";
      #     chars = "\x1b[88;5u";
      #   }
      #   {
      #     key = "Y";
      #     mods = "Control|Shift";
      #     chars = "\x1b[89;5u";
      #   }
      #   {
      #     key = "Z";
      #     mods = "Control|Shift";
      #     chars = "\x1b[90;5u";
      #   }

      #   # Control bindings
      #   {
      #     key = "A";
      #     mods = "Control";
      #     chars = "\x1b[65;5u";
      #   }
        {
          key = "B";
          mods = "Control";
          chars = "\x1b[66;5u";
        }
      #   {
      #     key = "C";
      #     mods = "Control";
      #     chars = "\x1b[67;5u";
      #   }
      #   {
      #     key = "D";
      #     mods = "Control";
      #     chars = "\x1b[68;5u";
      #   }
      #   {
      #     key = "E";
      #     mods = "Control";
      #     chars = "\x1b[69;5u";
      #   }
      #   {
      #     key = "F";
      #     mods = "Control";
      #     chars = "\x1b[70;5u";
      #   }
      #   {
      #     key = "G";
      #     mods = "Control";
      #     chars = "\x1b[71;5u";
      #   }
      #   {
      #     key = "H";
      #     mods = "Control";
      #     chars = "\x1b[72;5u";
      #   }
      #   {
      #     key = "I";
      #     mods = "Control";
      #     chars = "\x1b[73;5u";
      #   }
      #   {
      #     key = "J";
      #     mods = "Control";
      #     chars = "\x1b[74;5u";
      #   }
      #   {
      #     key = "K";
      #     mods = "Control";
      #     chars = "\x1b[75;5u";
      #   }
      #   {
      #     key = "L";
      #     mods = "Control";
      #     chars = "\x1b[76;5u";
      #   }
      #   {
      #     key = "M";
      #     mods = "Control";
      #     chars = "\x1b[77;5u";
      #   }
      #   {
      #     key = "N";
      #     mods = "Control";
      #     chars = "\x1b[78;5u";
      #   }
      #   {
      #     key = "O";
      #     mods = "Control";
      #     chars = "\x1b[79;5u";
      #   }
      #   {
      #     key = "P";
      #     mods = "Control";
      #     chars = "\x1b[80;5u";
      #   }
      #   {
      #     key = "Q";
      #     mods = "Control";
      #     chars = "\x1b[81;5u";
      #   }
      #   {
      #     key = "R";
      #     mods = "Control";
      #     chars = "\x1b[82;5u";
      #   }
      #   {
      #     key = "S";
      #     mods = "Control";
      #     chars = "\x1b[83;5u";
      #   }
      #   {
      #     key = "T";
      #     mods = "Control";
      #     chars = "\x1b[84;5u";
      #   }
      #   {
      #     key = "U";
      #     mods = "Control";
      #     chars = "\x1b[85;5u";
      #   }
      #   {
      #     key = "V";
      #     mods = "Control";
      #     chars = "\x1b[86;5u";
      #   }
      #   {
      #     key = "W";
      #     mods = "Control";
      #     chars = "\x1b[87;5u";
      #   }
      #   {
      #     key = "X";
      #     mods = "Control";
      #     chars = "\x1b[88;5u";
      #   }
      #   {
      #     key = "Y";
      #     mods = "Control";
      #     chars = "\x1b[89;5u";
      #   }
      #   {
      #     key = "Z";
      #     mods = "Control";
      #     chars = "\x1b[90;5u";
      #   }
      ];
    };
  };
}
