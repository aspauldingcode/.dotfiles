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
        padding.x = 0;
        # padding.y = 10; # pretty lavat
        opacity = 1.0;
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
      live_config_reload = true;

      selection = {
        save_to_clipboard = true; # copy on selection
      };

      keyboard.bindings = [
        # {
        #   key = "C";
        #   mods = "Control";
        #   action = "Copy";
        # }
        # {
        #   key = "C";
        #   mods = "Shift|Control";
        #   action = "ReceiveChar";
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
