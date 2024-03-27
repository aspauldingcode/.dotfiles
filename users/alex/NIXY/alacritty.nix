{ config, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
        padding.x =       0;
        padding.y =       10;
        opacity   =       0.9;
        blur =            true;
        class.instance =  "Alacritty";
        class.general  =  "Alacritty";
        decorations =     "Buttonless";
        option_as_alt =   "Both";
      };

      scrolling = {
        history =     10000;
        multiplier =  3;
      };

      font = {
        normal = {
          family =  "Hack Nerd Font Mono";
          style =   "Regular";
        };
        bold = {
          family =  "Hack Nerd Font Mono";
          style =   "Bold";
        };
        italic = {
          family =  "Hack Nerd Font Mono";
          style =   "Italic";
        };
        size =      12.0;
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

      selection = {
        save_to_clipboard = true; #copy on selection
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


        /*
    # shortcuts for tmux. the leader key is control-b (0x02)
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
