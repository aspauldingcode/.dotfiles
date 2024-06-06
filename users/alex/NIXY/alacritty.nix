{ config, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
        padding.x = 0;
        #padding.y = 10;
        opacity = 0.9;
        blur = true;
        class.instance = "Alacritty";
        class.general = "Alacritty";
        decorations = "None";   # "Full" | "None" | "Transparent" | "Buttonless"
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
        size = 12.0;
      };

      # Becomes either 'dark' or 'light', based on your colors! (in qutebrowser)
      #webppage.preferred_color_scheme = "${config.colorScheme.kind}";

      colors = {
        primary = {
          foreground = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
          background = "#${config.colorScheme.colors.base00}";  # Default Background
          dim_foreground = "#${config.colorScheme.colors.base01}";  # Lighter Background (Used for status bars, line number and folding marks)
          bright_foreground = "#${config.colorScheme.colors.base06}";  # Light Foreground (Not often used)
        };

        cursor = {
          text = "#${config.colorScheme.colors.base00}";  # Default Background
          cursor = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
        };

        vi_mode_cursor = {
          text = "#${config.colorScheme.colors.base00}";  # Default Background
          cursor = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
        };

        search = {
          matches = {
            foreground = "#${config.colorScheme.colors.base00}";  # Default Background
            background = "#${config.colorScheme.colors.base08}";  # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          };
          focused_match = {
            foreground = "#${config.colorScheme.colors.base00}";  # Default Background
            background = "#${config.colorScheme.colors.base0A}";  # Classes, Markup Bold, Search Text Background
          };
        };

        hints = {
          start = {
            foreground = "#${config.colorScheme.colors.base00}";  # Default Background
            background = "#${config.colorScheme.colors.base0A}";  # Classes, Markup Bold, Search Text Background
          };
          end = {
            foreground = "#${config.colorScheme.colors.base00}";  # Default Background
            background = "#${config.colorScheme.colors.base08}";  # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          };
        };

        line_indicator = {
          foreground = "None";  # Uses opposing primary color
          background = "None";  # Uses opposing primary color
        };

        footer_bar = {
          foreground = "#${config.colorScheme.colors.base00}";  # Default Background
          background = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
        };

        selection = {
          text = "#${config.colorScheme.colors.base00}";  # Default Background
          background = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
        };

        normal = {
          black = "#${config.colorScheme.colors.base00}";  # Default Background
          red = "#${config.colorScheme.colors.base08}";    # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          green = "#${config.colorScheme.colors.base0B}";  # Strings, Inherited Class, Markup Code, Diff Inserted
          yellow = "#${config.colorScheme.colors.base0A}"; # Classes, Markup Bold, Search Text Background
          blue = "#${config.colorScheme.colors.base0D}";   # Functions, Methods, Attribute IDs, Headings
          magenta = "#${config.colorScheme.colors.base0E}"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          cyan = "#${config.colorScheme.colors.base0C}"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          white = "#${config.colorScheme.colors.base05}";  # Default Foreground, Caret, Delimiters, Operators
        };

        bright = {
          black = "#${config.colorScheme.colors.base03}";  # Comments, Invisibles, Line Highlighting
          red = "#${config.colorScheme.colors.base08}";    # Integers, Boolean, Constants, XML Attributes, Markup Link Url
          green = "#${config.colorScheme.colors.base0B}";  # Strings, Inherited Class, Markup Code, Diff Inserted
          yellow = "#${config.colorScheme.colors.base0A}"; # Classes, Markup Bold, Search Text Background
          blue = "#${config.colorScheme.colors.base0D}";   # Functions, Methods, Attribute IDs, Headings
          magenta = "#${config.colorScheme.colors.base0E}"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          cyan = "#${config.colorScheme.colors.base0C}"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          white = "#${config.colorScheme.colors.base07}";  # Light Background (Not often used)
        };

        dim = {
          black = "#${config.colorScheme.colors.base01}";  # Lighter Background (Used for status bars, line number and folding marks)
          red = "#${config.colorScheme.colors.base02}";    # Selection Background
          green = "#${config.colorScheme.colors.base03}";  # Comments, Invisibles, Line Highlighting
          yellow = "#${config.colorScheme.colors.base04}";  # Dark Foreground (Used for status bars)
          blue = "#${config.colorScheme.colors.base05}";   # Default Foreground, Caret, Delimiters, Operators
          magenta = "#${config.colorScheme.colors.base06}"; # Light Foreground (Not often used)
          cyan = "#${config.colorScheme.colors.base07}"; # Light Background (Not often used)
          white = "#${config.colorScheme.colors.base08}";  # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
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
        #    key = "C";
        #    mods = "Control|Shift";
        #    chars = "\\u0003";
        # }
        # {
        #    key = "C";
        #    mods = "Control";
        #    action = "Copy";
        # }
        # {
        #    key = "V";
        #    mods = "Control";
        #    action = "Paste";
        # }

        # You can use the ReceivedChar as action for Ctrl + Shift + C, so it'll have SIGINT, and your binding for ctrl+c. The new syntax for \x03 is \U0003, the migrator translates them correctly.

        /* # shortcuts for tmux. the leader key is control-b (0x02)
           - { key: W,        mods: Command,       chars: "\x02&"                       }  # close tab (kill)
           - { key: T,        mods: Command,       chars: "\x02c"                       }  # new tab
           - { key: RBracket, mods: Command|Shift, chars: "\x02n"                       }  # select next tab
           - { key: LBracket, mods: Command|Shift, chars: "\x02p"                       }  # select previous tab
           - { key: RBracket, mods: Command,       chars: "\x02o"                       }  # select next pane
           - { key: LBracket, mods: Command,       chars: "\x02;"                       }  # select last (previously used) pane
           - { key: F,        mods: Command,       chars: "\x02/"                       }  # search (upwards) (see tmux.conf)
        */

        # {
        #     key = "f";
        #     mode = "";
        #     action = "";
        # }
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
