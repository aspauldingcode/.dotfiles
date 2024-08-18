{ config, lib, pkgs, ... }:

let
  inherit (config.colorscheme) colors;
in
{
  programs.bemenu = {
    enable = true;
    settings = {
      line-height = 28;                # Defines the height to make each menu line
      prompt = "search";               # Defines the prompt text to be displayed
      ignorecase = true;               # Match items case insensitively
      wrap = false;                    # Disable wrap around cursor selection
      #index = 1;                       # Select item at index automatically
      no-cursor = false;               # Ignore cursor events
      no-touch = false;                # Ignore touch events
      no-keyboard = false;             # Ignore keyboard events
      scrollbar = "autohide";          # Display scrollbar (none, always, autohide)
      grab = true;                     # Show the menu before reading stdin
      monitor = 0;                     # Index of monitor where menu will appear
      border-radius = 5;               # Defines the radius of the border around the menu
      # H = 20;                          # define the menu height to match cursor height
      # M = 20;                          # define the Margin to match cursor height
      ch = 20;                         # Defines the height of the cursor
      cw = 2;                          # Defines the width of the cursor (make it thin)
      hp = 10;                         # Defines the horizontal padding for the entries in single line mode
      fn = "monospace 12";             # Defines the font to be used

      # Color settings
      tb = "#${colors.base00}";        # Title background color
      tf = "#${colors.base05}";        # Title foreground color (lighter)
      fb = "#${colors.base00}";        # Filter background color
      ff = "#${colors.base05}";        # Filter foreground color (lighter)
      cb = "#${colors.base00}";        # Cursor background color
      cf = "#${colors.base05}";        # Cursor foreground color (darker)
      nb = "#${colors.base00}";        # Normal background color
      nf = "#${colors.base05}";        # Normal foreground color (lighter)
      hb = "#${colors.base0C}";        # Highlighted background color
      hf = "#${colors.base00}";        # Highlighted foreground color (darker)
      fbb = "#${colors.base00}";       # Feedback background color
      fbf = "#${colors.base05}";       # Feedback foreground color (lighter)
      sb = "#${colors.base0C}";        # Selected background color
      sf = "#${colors.base00}";        # Selected foreground color (darker)
      ab = "#${colors.base00}";        # alternate foreground color (darker)
      af = "#${colors.base05}";        # alternate foreground color (darker)
      scb = "#${colors.base02}";       # Scrollbar background color
      scf = "#${colors.base05}";       # Scrollbar foreground color (darker)
      bdr = "#${colors.base07}";       # Border color
    };
  };
}
