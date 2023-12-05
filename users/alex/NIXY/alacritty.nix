{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 0;
        padding.y = 10;
        opacity   = 0.9;
        class.instance = "Alacritty";
        class.general  = "Alacritty";
        decorations = "buttonless";
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = {
          family = "DejaVu Sans Mono";
          style = "Book";
        };
        bold = {
          family = "DejaVu Sans Mono";
          style = "Bold";
        };
        italic = {
          family = "DejaVu Sans Mono";
          style = "Oblique";
        };
        size = 16.0;
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
      purple  ="#${config.colorScheme.colors.base0E}";
      aqua    ="#${config.colorScheme.colors.base0C}";
      gray    ="#${config.colorScheme.colors.base05}";
    };
    bright = {
      black   ="#${config.colorScheme.colors.base03}";
      red     ="#${config.colorScheme.colors.base08}";
      green   ="#${config.colorScheme.colors.base0B}";
      yellow  ="#${config.colorScheme.colors.base0A}";
      blue    ="#${config.colorScheme.colors.base0D}";
      purple  ="#${config.colorScheme.colors.base0E}";
      aqua    ="#${config.colorScheme.colors.base0C}";
      gray    ="#${config.colorScheme.colors.base07}";
    };
    };
  
 cursor = {
    style = "Beam";
    blinking = "On";
    blink_interval = 750;
  };

  draw_bold_text_with_bright_colors = true;
  live_config_reload = true;

  key_bindings = [
    {
      key = "F";
      mods = "Alt|Shift";
      action = "ToggleSimpleFullscreen";
    }
    # {
       # key = "C";
       # mods = "Control|Shift";
       # chars = "\\x03";
    # }
    # {
    #   key = "C";
    #   mods = "Command";
    #   action = "Copy";
    # }
    # {
    #   key = "V";
    #   mods = "Control";
    #   action = "Paste";
    # }
    # {
    #   key = "Period"; 
    #   mods = "Control";
    # }
    #- { key: L,         mods: Control,                    action: ClearLogNotice }
    #- { key: L,         mods: Control, mode: ~Vi|~Search, chars: "\x0c"          }
  {
    key = "PageUp";
          #mods = "Shift";   
          mode = "~Alt";
          action = "ScrollPageUp";
        }
        { 
          key = "PageDown";
          #mods = "Shift";
          mode = "~Alt";
          action = "ScrollPageDown";
        }
        #{ key: Home,      mods: Shift,   mode: ~Alt,        action: ScrollToTop    }
        #- { key: End,       mods: Shift,   mode: ~Alt,        action: ScrollToBottom }
      ];
    };
  };
}
