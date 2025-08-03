{
  config,
  pkgs,
  ...
}: let
  inherit (config.colorScheme) palette;
in {
  programs.kitty = {
    enable = false;
    package = pkgs.kitty; # Use nixpkgs kitty package
    darwinLaunchOptions = []; # No special launch options needed
    environment = {}; # No extra environment variables needed
    extraConfig = ""; # No extra config needed

    shellIntegration = {
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      mode = "enabled"; # Full shell integration
    };

    themeFile = null; # Using custom colors instead of a theme

    font = {
      name = "JetBrains Mono";
      size = 12.0;
      package = null; # Use system font
    };

    settings = {
      # Basic settings
      confirm_os_window_close = 0;
      shell_integration = "no-cursor";
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";
      scrollback_lines = 2000;
      scrollback_pager = "less +G -R";
      wheel_scroll_multiplier = "5.0";
      click_interval = "0.5";
      select_by_word_characters = ":@-./_~?&=%+#";
      mouse_hide_wait = "0.0";
      enabled_layouts = "*";
      remember_window_size = "no";
      initial_window_width = 640;
      initial_window_height = 400;
      repaint_delay = 10;
      input_delay = 3;
      visual_bell_duration = "0.0";
      enable_audio_bell = "yes";
      open_url_modifiers = "ctrl+shift";
      open_url_with = "default";
      term = "xterm-kitty";
      window_border_width = 0;
      window_margin_width = 0;
      window_padding_width = 0;
      hide_window_decorations = "titlebar-only";
      macos_option_as_alt = "yes";
      allow_remote_control = "yes";
      copy_on_select = "yes"; # Enable copy on select

      # Colors
      foreground = "#${palette.base05}";
      background = "#${palette.base00}";
      selection_background = "#${palette.base05}";
      selection_foreground = "#${palette.base00}";
      url_color = "#${palette.base04}";
      cursor = "#${palette.base05}";
      cursor_text_color = "#${palette.base00}";
      active_border_color = "#${palette.base03}";
      inactive_border_color = "#${palette.base01}";
      active_tab_background = "#${palette.base00}";
      active_tab_foreground = "#${palette.base05}";
      inactive_tab_background = "#${palette.base01}";
      inactive_tab_foreground = "#${palette.base04}";
      tab_bar_background = "#${palette.base01}";
      wayland_titlebar_color = "#${palette.base00}";
      macos_titlebar_color = "#${palette.base00}";

      # Normal colors (0-7)
      color0 = "#${palette.base00}";
      color1 = "#${palette.base08}";
      color2 = "#${palette.base0B}";
      color3 = "#${palette.base0A}";
      color4 = "#${palette.base0D}";
      color5 = "#${palette.base0E}";
      color6 = "#${palette.base0C}";
      color7 = "#${palette.base05}";

      # Bright colors (8-15)
      color8 = "#${palette.base03}";
      color9 = "#${palette.base08}";
      color10 = "#${palette.base0B}";
      color11 = "#${palette.base0A}";
      color12 = "#${palette.base0D}";
      color13 = "#${palette.base0E}";
      color14 = "#${palette.base0C}";
      color15 = "#${palette.base07}";

      # Extended base16 colors (16-21)
      color16 = "#${palette.base09}";
      color17 = "#${palette.base0F}";
      color18 = "#${palette.base01}";
      color19 = "#${palette.base02}";
      color20 = "#${palette.base04}";
      color21 = "#${palette.base06}";
    };

    keybindings = {
      # Basic copy/paste
      "super+c" = "copy_to_clipboard";
      "super+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "shift+insert" = "paste_from_selection";

      # Font size
      "ctrl+shift+backspace" = "restore_font_size";
      "ctrl+shift+down" = "decrease_font_size";
      "ctrl+shift+up" = "increase_font_size";

      # Navigation
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+h" = "show_scrollback";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+j" = "scroll_line_down";
      "ctrl+shift+k" = "scroll_line_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+page_up" = "scroll_page_up";

      # Tab management
      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+t" = "new_tab";

      # Window management
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+`" = "move_window_to_top";
      "ctrl+shift+b" = "move_window_backward";
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+l" = "next_layout";
      "super+n" = "new_os_window";
      "super+w" = "close_window";

      # Window selection
      "ctrl+shift+0" = "tenth_window";
      "ctrl+shift+1" = "first_window";
      "ctrl+shift+2" = "second_window";
      "ctrl+shift+3" = "third_window";
      "ctrl+shift+4" = "fourth_window";
      "ctrl+shift+5" = "fifth_window";
      "ctrl+shift+6" = "sixth_window";
      "ctrl+shift+7" = "seventh_window";
      "ctrl+shift+8" = "eighth_window";
      "ctrl+shift+9" = "ninth_window";
    };
  };
}
