{
  config,
  pkgs,
  ...
}:
# yazi configuration!
# FIXME: why is yazi broken on nixos?
let
  inherit (config.colorScheme) palette;
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    settings = {
      "$schema" = "https://yazi-rs.github.io/schemas/yazi.json";
    };
    keymap = {
      # A TOML linter such as https://taplo.tamasfe.dev/ can use this schema to validate your config.
      # If you encounter any issues, please make an issue at https://github.com/yazi-rs/schemas.
      "$schema" = "https://yazi-rs.github.io/schemas/keymap.json";
    };
    theme = {
      "$schema" = "https://yazi-rs.github.io/schemas/theme.json";
      flavor = {
        use = "";
      };
      manager = {
        cwd = {
          fg = "#${palette.base0C}";
        };
        hovered = {
          reversed = true;
        };
        preview_hovered = {
          underline = true;
        };
        find_keyword = {
          fg = "#${palette.base0A}";
          bold = true;
          italic = true;
          underline = true;
        };
        find_position = {
          fg = "#${palette.base0E}";
          bg = "reset";
          bold = true;
          italic = true;
        };
        marker_copied = {
          fg = "#${palette.base0B}";
          bg = "#${palette.base0B}";
        };
        marker_cut = {
          fg = "#${palette.base08}";
          bg = "#${palette.base08}";
        };
        marker_marked = {
          fg = "#${palette.base0C}";
          bg = "#${palette.base0C}";
        };
        marker_selected = {
          fg = "#${palette.base0A}";
          bg = "#${palette.base0A}";
        };
        tab_active = {
          reversed = true;
        };
        tab_inactive = { };
        tab_width = 1;
        count_copied = {
          fg = "#${palette.base07}";
          bg = "#${palette.base0B}";
        };
        count_cut = {
          fg = "#${palette.base07}";
          bg = "#${palette.base08}";
        };
        count_selected = {
          fg = "#${palette.base07}";
          bg = "#${palette.base0A}";
        };
        border_symbol = "│";
        border_style = {
          fg = "#${palette.base03}";
        };
        syntect_theme = "";
      };
      status = {
        separator_open = "";
        separator_close = "";
        separator_style = {
          fg = "#${palette.base03}";
          bg = "#${palette.base03}";
        };
        mode_normal = {
          bg = "#${palette.base0D}";
          bold = true;
        };
        mode_select = {
          bg = "#${palette.base08}";
          bold = true;
        };
        mode_unset = {
          bg = "#${palette.base08}";
          bold = true;
        };
        progress_label = {
          bold = true;
        };
        progress_normal = {
          fg = "#${palette.base0D}";
          bg = "#${palette.base00}";
        };
        progress_error = {
          fg = "#${palette.base08}";
          bg = "#${palette.base00}";
        };
        permissions_t = {
          fg = "#${palette.base0B}";
        };
        permissions_r = {
          fg = "#${palette.base0A}";
        };
        permissions_w = {
          fg = "#${palette.base08}";
        };
        permissions_x = {
          fg = "#${palette.base0C}";
        };
        permissions_s = {
          fg = "#${palette.base03}";
        };
      };
      # Add more theme keys and use all base16 colors
      select = {
        border = {
          fg = "#${palette.base0D}";
        };
        active = {
          fg = "#${palette.base0E}";
          bold = true;
        };
        inactive = {
          fg = "#${palette.base01}";
        };
      };
      confirm = {
        border = {
          fg = "#${palette.base0F}";
        };
        title = {
          fg = "#${palette.base04}";
        };
        content = {
          fg = "#${palette.base05}";
        };
        list = {
          fg = "#${palette.base06}";
        };
        btn_yes = {
          fg = "#${palette.base0B}";
        };
        btn_no = {
          fg = "#${palette.base08}";
        };
        btn_labels = [
          "Yes"
          "No"
        ];
      };
      filetype = {
        rules = [
          {
            fg = "#${palette.base0C}";
            mime = "image/*";
          }
          {
            fg = "#${palette.base0A}";
            mime = "video/*";
          }
          {
            fg = "#${palette.base0F}";
            mime = "audio/*";
          }
          {
            fg = "#${palette.base02}";
            mime = "application/x-bzip";
          }
        ];
      };
      notify = {
        icon_error = "\uf057";
        icon_info = "\uf05a";
        icon_warn = "\uf071";
        title_error = {
          fg = "#${palette.base08}";
        };
        title_info = {
          fg = "#${palette.base0B}";
        };
        title_warn = {
          fg = "#${palette.base0A}";
        };
      };
      tasks = {
        border = {
          fg = "#${palette.base0D}";
        };
        hovered = {
          fg = "#${palette.base0E}";
          underline = true;
        };
        title = { };
      };
      which = {
        cand = {
          fg = "#${palette.base0C}";
        };
        cols = 3;
        desc = {
          fg = "#${palette.base0E}";
        };
        mask = {
          bg = "#${palette.base00}";
        };
        rest = {
          fg = "#${palette.base03}";
        };
        separator = " \uea9c ";
        separator_style = {
          fg = "#${palette.base03}";
        };
      };
      icon = {
        files = [
          {
            name = "ai";
            text = "\uf042";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "avi";
            text = "\uf0aa";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "bat";
            text = "\ue795";
            fg_dark = "#${palette.base0F}";
            fg_light = "#${palette.base0F}";
          }
          {
            name = "bin";
            text = "\uf471";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "bmp";
            text = "\uf1c5";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "c";
            text = "\ue61e";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "cc";
            text = "\ue61e";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "cl";
            text = "\ue61f";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "cmake";
            text = "\ue61f";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "cpp";
            text = "\ue61d";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "cs";
            text = "\uf81a";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "css";
            text = "\uf13c";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "csv";
            text = "\uf021";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "d";
            text = "\uf1c0";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "dart";
            text = "\ueae5";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "db";
            text = "\uf1c0";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "desktop";
            text = "\ue79e";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "diff";
            text = "\uf068";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "doc";
            text = "\uf1c2";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "docx";
            text = "\uf1c2";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "drawio";
            text = "\uf0b1";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "dropbox";
            text = "\uf16b";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "eex";
            text = "\ue60e";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "elm";
            text = "\ue62c";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "eot";
            text = "\uf031";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "epub";
            text = "\ue600";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "erb";
            text = "\ue21e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "erl";
            text = "\ue60e";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "ex";
            text = "\ue60d";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "exs";
            text = "\ue60d";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "f#";
            text = "\ue7a7";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "favicon";
            text = "\uf007";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "fish";
            text = "\uf489";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "flac";
            text = "\uf001";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "fsharp";
            text = "\ue7a7";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "gdoc";
            text = "\uf1c2";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "gemfile";
            text = "\ue21e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "gif";
            text = "\uf1c5";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "go";
            text = "\ue626";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "godot";
            text = "\ue7a8";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "gruntfile";
            text = "\ue21e";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "gz";
            text = "\uf410";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "h";
            text = "\ue61e";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "hpp";
            text = "\ue61d";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "hs";
            text = "\ue777";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "html";
            text = "\uf13b";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "ico";
            text = "\uf1c5";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "java";
            text = "\uf004";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "jpg";
            text = "\uf1c5";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "jpeg";
            text = "\uf1c5";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "json";
            text = "\ue60b";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "jsx";
            text = "\ue7ba";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "key";
            text = "\uf084";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "kts";
            text = "\ue628";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "less";
            text = "\ue749";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "lock";
            text = "\uf023";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "lua";
            text = "\ue620";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "m";
            text = "\uf095";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "markdown";
            text = "\uf48a";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "md";
            text = "\uf48a";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "mdx";
            text = "\uf48a";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "mov";
            text = "\uf03d";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "mp3";
            text = "\uf001";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "mp4";
            text = "\uf03d";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "nix";
            text = "\ue779";
            fg_dark = "#${palette.base0F}";
            fg_light = "#${palette.base0F}";
          }
          {
            name = "node_modules";
            text = "\ue718";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "npmignore";
            text = "\ue71e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "npmrc";
            text = "\ue71e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "odt";
            text = "\uf1c2";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "opus";
            text = "\uf001";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "otf";
            text = "\uf031";
            fg_dark = "#${palette.base00}";
            fg_light = "#${palette.base00}";
          }
          {
            name = "pdf";
            text = "\uf1c1";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "php";
            text = "\ue73d";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "png";
            text = "\uf1c5";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "ppt";
            text = "\uf1c4";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "pptx";
            text = "\uf1c4";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "procfile";
            text = "\ue21e";
            fg_dark = "#${palette.base0F}";
            fg_light = "#${palette.base0F}";
          }
          {
            name = "py";
            text = "\ue606";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "pyc";
            text = "\ue606";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "pyo";
            text = "\ue606";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "r";
            text = "\uf25d";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "rakefile";
            text = "\ue21e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "rb";
            text = "\ue21e";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "rs";
            text = "\ue7a8";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "rss";
            text = "\uf09e";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "rtf";
            text = "\uf1c2";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "sass";
            text = "\ue603";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "scss";
            text = "\ue603";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "sh";
            text = "\uf489";
            fg_dark = "#${palette.base0F}";
            fg_light = "#${palette.base0F}";
          }
          {
            name = "slim";
            text = "\ue73b";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "sql";
            text = "\ue706";
            fg_dark = "#${palette.base05}";
            fg_light = "#${palette.base05}";
          }
          {
            name = "sqlite3";
            text = "\ue706";
            fg_dark = "#${palette.base05}";
            fg_light = "#${palette.base05}";
          }
          {
            name = "styl";
            text = "\ue600";
            fg_dark = "#${palette.base0A}";
            fg_light = "#${palette.base0A}";
          }
          {
            name = "sublime-package";
            text = "\uf0f6";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "sublime-settings";
            text = "\uf0f6";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "svg";
            text = "\uf1c5";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "swift";
            text = "\ue755";
            fg_dark = "#${palette.base08}";
            fg_light = "#${palette.base08}";
          }
          {
            name = "tar";
            text = "\uf410";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "tex";
            text = "\ue600";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "ts";
            text = "\ue628";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "tsx";
            text = "\ue7ba";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "ttf";
            text = "\uf031";
            fg_dark = "#${palette.base00}";
            fg_light = "#${palette.base00}";
          }
          {
            name = "txt";
            text = "\uf15c";
            fg_dark = "#${palette.base09}";
            fg_light = "#${palette.base09}";
          }
          {
            name = "video";
            text = "\uf03d";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "vue";
            text = "\ue62d";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "webp";
            text = "\uf1c5";
            fg_dark = "#${palette.base0E}";
            fg_light = "#${palette.base0E}";
          }
          {
            name = "xls";
            text = "\uf1c3";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "xlsx";
            text = "\uf1c3";
            fg_dark = "#${palette.base0B}";
            fg_light = "#${palette.base0B}";
          }
          {
            name = "xml";
            text = "\uf1c4";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "yarn.lock";
            text = "\ue718";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "yml";
            text = "\uf481";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "zip";
            text = "\uf410";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
        ];
        directories = [
          {
            name = ".config";
            text = "\uf423";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = ".git";
            text = "\ue5fb";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = ".github";
            text = "\uf7b2";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = ".gitignore";
            text = "\ue702";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = ".npmignore";
            text = "\ue71e";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = ".vscode";
            text = "\ue70c";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "bin";
            text = "\ue5fc";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "build";
            text = "\ueb2a";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "ci";
            text = "\uf085";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "dist";
            text = "\uf78d";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "doc";
            text = "\uf1c2";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "docs";
            text = "\uf7b8";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "img";
            text = "\uf302";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "include";
            text = "\uf7b8";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "lib";
            text = "\uf7b8";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "logs";
            text = "\uf70e";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "node_modules";
            text = "\uf898";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "public";
            text = "\uf015";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "src";
            text = "\ufb66";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
          {
            name = "test";
            text = "\uf490";
            fg_dark = "#${palette.base0D}";
            fg_light = "#${palette.base0D}";
          }
        ];
      };
    };
  };
}
