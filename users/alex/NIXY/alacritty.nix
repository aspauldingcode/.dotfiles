{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 0;
        padding.y = 10;
        opacity   = 1;
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

      colors = {
        primary = {
          background = "0x282828";
          foreground = "0xEBDBB2";
        };
      #cursor = {
      #text    ="0xEBEBEB";
      #cursor  ="0xEBEBEB";
      #};
      normal = {#TRYING TO GRUVBOX IT
      black   ="0x0d0d0d";
      red     ="0xCC241D";
      green   ="0x98971A";
      yellow  ="0xD79921";
      blue    ="0x458588";
      purple  ="0xB16286";
      aqua    ="0x689D6A";
      gray    ="0xa89984";
    };
    bright = {
      black   ="0x6D7070";
      red     ="0xFB4934";
      green   ="0xB8BB26";
      yellow  ="0xFABD2F";
      blue    ="0x83A598";
      purple  ="0xD3869B";
      aqua    ="0x8EC07C";
      gray    ="0x928374";
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
    {
      key = "C";
      mods = "Control|Shift";
      action = "Copy";
    }
    {
      key = "V";
      mods = "Control";
      action = "Paste";
    }
    {
      key = "C"; 
      mods = "Control";
      chars = "\\x03";
    }
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
