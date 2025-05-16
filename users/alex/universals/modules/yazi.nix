{ config, pkgs, ... }:

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

      manager = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = false;
        linemode = "none";
        show_hidden = false;
        show_symlink = true;
        scrolloff = 5;
      };

      preview = {
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        image_filter = "triangle";
        image_quality = 75;
        sixel_fraction = 15;
        ueberzug_scale = 1;
        ueberzug_offset = [
          0
          0
          0
          0
        ];
      };

      opener = {
        edit = [
          {
            run = "nvim $@";
            desc = "Open in Neovim";
            block = true;
            for = "unix";
          }
          {
            run = "code %*";
            desc = "Open in VS Code";
            orphan = true;
            for = "windows";
          }
          {
            run = "code -w %*";
            desc = "Open in VS Code (blocking)";
            block = true;
            for = "windows";
          }
        ];
        open = [
          {
            run = "xdg-open $@";
            desc = "Open with default app";
            for = "linux";
          }
          {
            run = "open $@";
            desc = "Open with default app";
            for = "macos";
          }
          {
            run = "start \"\" %1";
            desc = "Open with default app";
            orphan = true;
            for = "windows";
          }
        ];
        reveal = [
          {
            run = "open -R $1";
            desc = "Reveal in Finder";
            for = "macos";
          }
          {
            run = "explorer /select, %1";
            desc = "Reveal in Explorer";
            orphan = true;
            for = "windows";
          }
          {
            run = "exiftool $1; echo \"Press enter to exit\"; read _";
            desc = "Show EXIF data";
            block = true;
            for = "unix";
          }
        ];
        extract = [
          {
            run = "unar $1";
            desc = "Extract archive";
            for = "unix";
          }
          {
            run = "unar %1";
            desc = "Extract archive";
            for = "windows";
          }
        ];
        play = [
          {
            run = "mpv $@";
            desc = "Play in mpv";
            orphan = true;
            for = "unix";
          }
          {
            run = "mpv %1";
            desc = "Play in mpv";
            orphan = true;
            for = "windows";
          }
          {
            run = "mediainfo $1; echo \"Press enter to exit\"; read _";
            desc = "Show media info";
            block = true;
            for = "unix";
          }
        ];
      };

      open = {
        rules = [
          {
            name = "*/";
            use = [
              "edit"
              "open"
              "reveal"
            ];
          }
          {
            mime = "text/*";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "image/*";
            use = [
              "open"
              "reveal"
            ];
          }
          {
            mime = "video/*";
            use = [
              "play"
              "reveal"
            ];
          }
          {
            mime = "audio/*";
            use = [
              "play"
              "reveal"
            ];
          }
          {
            mime = "inode/x-empty";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "application/json";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "*/javascript";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "application/zip";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/gzip";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/x-tar";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/x-bzip";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/x-bzip2";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/x-7z-compressed";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/x-rar";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/xz";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "*";
            use = [
              "open"
              "reveal"
            ];
          }
        ];
      };

      tasks = {
        micro_workers = 10;
        macro_workers = 25;
        bizarre_retry = 5;
        image_alloc = 536870912;
        image_bound = [
          0
          0
        ];
        suppress_preload = false;
      };

      plugin = {
        preloaders = [
          {
            mime = "image/vnd.djvu";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            mime = "application/pdf";
            run = "pdf";
          }
        ];
        previewers = [
          {
            name = "*/";
            run = "folder";
            sync = true;
          }
          {
            mime = "text/*";
            run = "code";
          }
          {
            mime = "*/xml";
            run = "code";
          }
          {
            mime = "*/javascript";
            run = "code";
          }
          {
            mime = "*/x-wine-extension-ini";
            run = "code";
          }
          {
            mime = "application/json";
            run = "json";
          }
          {
            mime = "image/vnd.djvu";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            mime = "application/pdf";
            run = "pdf";
          }
          {
            mime = "application/zip";
            run = "archive";
          }
          {
            mime = "application/gzip";
            run = "archive";
          }
          {
            mime = "application/x-tar";
            run = "archive";
          }
          {
            mime = "application/x-bzip";
            run = "archive";
          }
          {
            mime = "application/x-bzip2";
            run = "archive";
          }
          {
            mime = "application/x-7z-compressed";
            run = "archive";
          }
          {
            mime = "application/x-rar";
            run = "archive";
          }
          {
            mime = "application/xz";
            run = "archive";
          }
          {
            name = "*";
            run = "file";
          }
        ];
      };

      input = {
        cd_title = "Change directory:";
        cd_origin = "top-center";
        cd_offset = [
          0
          2
          50
          3
        ];

        # create_title = "Create:"; FIXME: breaks nixos yazi
        create_title = [
          "Create:"
          " "
        ]; # Array of two elements: title and optional separator/space
        create_origin = "top-center";
        create_offset = [
          0
          2
          50
          3
        ];

        rename_title = "Rename:";
        rename_origin = "hovered";
        rename_offset = [
          0
          1
          50
          3
        ];

        trash_title = "Move {n} selected file{s} to trash? (y/N)";
        trash_origin = "top-center";
        trash_offset = [
          0
          2
          50
          3
        ];

        delete_title = "Delete {n} selected file{s} permanently? (y/N)";
        delete_origin = "top-center";
        delete_offset = [
          0
          2
          50
          3
        ];

        filter_title = "Filter:";
        filter_origin = "top-center";
        filter_offset = [
          0
          2
          50
          3
        ];

        find_title = [
          "Find next:"
          "Find previous:"
        ];
        find_origin = "top-center";
        find_offset = [
          0
          2
          50
          3
        ];

        search_title = "Search via {n}:";
        search_origin = "top-center";
        search_offset = [
          0
          2
          50
          3
        ];

        shell_title = [
          "Shell:"
          "Shell (block):"
        ];
        shell_origin = "top-center";
        shell_offset = [
          0
          2
          50
          3
        ];

        overwrite_title = "Overwrite an existing file? (y/N)";
        overwrite_origin = "top-center";
        overwrite_offset = [
          0
          2
          50
          3
        ];

        quit_title = "{n} task{s} running, sure to quit? (y/N)";
        quit_origin = "top-center";
        quit_offset = [
          0
          2
          50
          3
        ];

        select = {
          open_title = "Open with:";
          open_origin = "hovered";
          open_offset = [
            0
            1
            50
            7
          ];
        };

        which = {
          sort_by = "none";
          sort_sensitive = false;
          sort_reverse = false;
        };

        log = {
          enabled = false;
        };

        headsup = { };
      };
    };
    keymap = {
      # A TOML linter such as https://taplo.tamasfe.dev/ can use this schema to validate your config.
      # If you encounter any issues, please make an issue at https://github.com/yazi-rs/schemas.
      "$schema" = "https://yazi-rs.github.io/schemas/keymap.json";

      manager = {
        keymap = [
          {
            on = "<Esc>";
            run = "escape";
            desc = "Exit visual mode, clear selected, or cancel search";
          }
          {
            on = "<C-[>";
            run = "escape";
            desc = "Exit visual mode, clear selected, or cancel search";
          }
          {
            on = "q";
            run = "quit";
            desc = "Exit the process";
          }
          {
            on = "Q";
            run = "quit --no-cwd-file";
            desc = "Exit the process without writing cwd-file";
          }
          {
            on = "<C-c>";
            run = "close";
            desc = "Close the current tab, or quit if it is last tab";
          }
          {
            on = "<C-z>";
            run = "suspend";
            desc = "Suspend the process";
          }

          # Hopping
          {
            on = "k";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "j";
            run = "arrow 1";
            desc = "Move cursor down";
          }

          {
            on = "<Up>";
            run = "arrow -1";
            desc = "Move cursor up";
          }
          {
            on = "<Down>";
            run = "arrow 1";
            desc = "Move cursor down";
          }

          {
            on = "<C-u>";
            run = "arrow -50%";
            desc = "Move cursor up half page";
          }
          {
            on = "<C-d>";
            run = "arrow 50%";
            desc = "Move cursor down half page";
          }
          {
            on = "<C-b>";
            run = "arrow -100%";
            desc = "Move cursor up one page";
          }
          {
            on = "<C-f>";
            run = "arrow 100%";
            desc = "Move cursor down one page";
          }

          {
            on = "<S-PageUp>";
            run = "arrow -50%";
            desc = "Move cursor up half page";
          }
          {
            on = "<S-PageDown>";
            run = "arrow 50%";
            desc = "Move cursor down half page";
          }
          {
            on = "<PageUp>";
            run = "arrow -100%";
            desc = "Move cursor up one page";
          }
          {
            on = "<PageDown>";
            run = "arrow 100%";
            desc = "Move cursor down one page";
          }

          {
            on = [
              "g"
              "g"
            ];
            run = "arrow -99999999";
            desc = "Move cursor to the top";
          }
          {
            on = "G";
            run = "arrow 99999999";
            desc = "Move cursor to the bottom";
          }

          # Navigation
          {
            on = "h";
            run = "leave";
            desc = "Go back to the parent directory";
          }
          {
            on = "l";
            run = "enter";
            desc = "Enter the child directory";
          }

          {
            on = "<Left>";
            run = "leave";
            desc = "Go back to the parent directory";
          }
          {
            on = "<Right>";
            run = "enter";
            desc = "Enter the child directory";
          }

          {
            on = "H";
            run = "back";
            desc = "Go back to the previous directory";
          }
          {
            on = "L";
            run = "forward";
            desc = "Go forward to the next directory";
          }

          # Seeking
          {
            on = "K";
            run = "seek -5";
            desc = "Seek up 5 units in the preview";
          }
          {
            on = "J";
            run = "seek 5";
            desc = "Seek down 5 units in the preview";
          }

          # Selection
          {
            on = "<Space>";
            run = [
              "select --state=none"
              "arrow 1"
            ];
            desc = "Toggle the current selection state";
          }
          {
            on = "v";
            run = "visual_mode";
            desc = "Enter visual mode (selection mode)";
          }
          {
            on = "V";
            run = "visual_mode --unset";
            desc = "Enter visual mode (unset mode)";
          }
          {
            on = "<C-a>";
            run = "select_all --state=true";
            desc = "Select all files";
          }
          {
            on = "<C-r>";
            run = "select_all --state=none";
            desc = "Inverse selection of all files";
          }

          # Operation
          {
            on = "o";
            run = "open";
            desc = "Open selected files";
          }
          {
            on = "O";
            run = "open --interactive";
            desc = "Open selected files interactively";
          }
          {
            on = "<Enter>";
            run = "open";
            desc = "Open selected files";
          }
          {
            on = "<S-Enter>";
            run = "open --interactive";
            desc = "Open selected files interactively";
          }
          {
            on = "y";
            run = "yank";
            desc = "Yank selected files (copy)";
          }
          {
            on = "x";
            run = "yank --cut";
            desc = "Yank selected files (cut)";
          }
          {
            on = "p";
            run = "paste";
            desc = "Paste yanked files";
          }
          {
            on = "P";
            run = "paste --force";
            desc = "Paste yanked files (overwrite if the destination exists)";
          }
          {
            on = "-";
            run = "link";
            desc = "Symlink the absolute path of yanked files";
          }
          {
            on = "_";
            run = "link --relative";
            desc = "Symlink the relative path of yanked files";
          }
          {
            on = "Y";
            run = "unyank";
            desc = "Cancel the yank status";
          }
          {
            on = "X";
            run = "unyank";
            desc = "Cancel the yank status";
          }
          {
            on = "d";
            run = "remove";
            desc = "Trash selected files";
          }
          {
            on = "D";
            run = "remove --permanently";
            desc = "Permanently delete selected files";
          }
          {
            on = "a";
            run = "create";
            desc = "Create a file (ends with / for directories)";
          }
          {
            on = "r";
            run = "rename --cursor=before_ext";
            desc = "Rename selected file(s)";
          }
          {
            on = ";";
            run = "shell --interactive";
            desc = "Run a shell command";
          }
          {
            on = ":";
            run = "shell --block --interactive";
            desc = "Run a shell command (block until finishes)";
          }
          {
            on = ".";
            run = "hidden toggle";
            desc = "Toggle the visibility of hidden files";
          }
          {
            on = "s";
            run = "search fd";
            desc = "Search files by name using fd";
          }
          {
            on = "S";
            run = "search rg";
            desc = "Search files by content using ripgrep";
          }
          {
            on = "<C-s>";
            run = "search none";
            desc = "Cancel the ongoing search";
          }
          {
            on = "z";
            run = "plugin zoxide";
            desc = "Jump to a directory using zoxide";
          }
          {
            on = "Z";
            run = "plugin fzf";
            desc = "Jump to a directory or reveal a file using fzf";
          }

          # Linemode
          {
            on = [
              "m"
              "s"
            ];
            run = "linemode size";
            desc = "Set linemode to size";
          }
          {
            on = [
              "m"
              "p"
            ];
            run = "linemode permissions";
            desc = "Set linemode to permissions";
          }
          {
            on = [
              "m"
              "c"
            ];
            run = "linemode ctime";
            desc = "Set linemode to ctime";
          }
          {
            on = [
              "m"
              "m"
            ];
            run = "linemode mtime";
            desc = "Set linemode to mtime";
          }
          {
            on = [
              "m"
              "o"
            ];
            run = "linemode owner";
            desc = "Set linemode to owner";
          }
          {
            on = [
              "m"
              "n"
            ];
            run = "linemode none";
            desc = "Set linemode to none";
          }

          # Copy
          {
            on = [
              "c"
              "c"
            ];
            run = "copy path";
            desc = "Copy the file path";
          }
          {
            on = [
              "c"
              "d"
            ];
            run = "copy dirname";
            desc = "Copy the directory path";
          }
          {
            on = [
              "c"
              "f"
            ];
            run = "copy filename";
            desc = "Copy the filename";
          }
          {
            on = [
              "c"
              "n"
            ];
            run = "copy name_without_ext";
            desc = "Copy the filename without extension";
          }

          # Filter
          {
            on = "f";
            run = "filter --smart";
            desc = "Filter files";
          }

          # Find
          {
            on = "/";
            run = "find --smart";
            desc = "Find next file";
          }
          {
            on = "?";
            run = "find --previous --smart";
            desc = "Find previous file";
          }
          {
            on = "n";
            run = "find_arrow";
            desc = "Go to the next found";
          }
          {
            on = "N";
            run = "find_arrow --previous";
            desc = "Go to the previous found";
          }

          # Sorting
          {
            on = [
              ","
              "m"
            ];
            run = [
              "sort modified --reverse=no"
              "linemode mtime"
            ];
            desc = "Sort by modified time";
          }
          {
            on = [
              ","
              "M"
            ];
            run = [
              "sort modified --reverse"
              "linemode mtime"
            ];
            desc = "Sort by modified time (reverse)";
          }
          {
            on = [
              ","
              "c"
            ];
            run = [
              "sort created --reverse=no"
              "linemode ctime"
            ];
            desc = "Sort by created time";
          }
          {
            on = [
              ","
              "C"
            ];
            run = [
              "sort created --reverse"
              "linemode ctime"
            ];
            desc = "Sort by created time (reverse)";
          }
          {
            on = [
              ","
              "n"
            ];
            run = [
              "sort name --reverse=no"
              "linemode none"
            ];
            desc = "Sort by name";
          }
          {
            on = [
              ","
              "N"
            ];
            run = [
              "sort name --reverse"
              "linemode none"
            ];
            desc = "Sort by name (reverse)";
          }
          {
            on = [
              ","
              "s"
            ];
            run = [
              "sort size --reverse=no"
              "linemode size"
            ];
            desc = "Sort by size";
          }
          {
            on = [
              ","
              "S"
            ];
            run = [
              "sort size --reverse"
              "linemode size"
            ];
            desc = "Sort by size (reverse)";
          }
          {
            on = [
              ","
              "e"
            ];
            run = [
              "sort ext --reverse=no"
              "linemode none"
            ];
            desc = "Sort by extension";
          }
          {
            on = [
              ","
              "E"
            ];
            run = [
              "sort ext --reverse"
              "linemode none"
            ];
            desc = "Sort by extension (reverse)";
          }

          # Tabs
          {
            on = "t";
            run = "tab_new";
            desc = "Open a new tab";
          }
          {
            on = "T";
            run = "tab_duplicate";
            desc = "Duplicate the current tab";
          }
          {
            on = "<C-w>";
            run = "tab_close";
            desc = "Close the current tab";
          }
          {
            on = "<C-T>";
            run = "tab_only";
            desc = "Close all tabs except the current one";
          }
          {
            on = "<Tab>";
            run = "tab_next";
            desc = "Go to the next tab";
          }
          {
            on = "<S-Tab>";
            run = "tab_previous";
            desc = "Go to the previous tab";
          }

          # Miscellaneous
          {
            on = "R";
            run = "reload";
            desc = "Reload the current directory";
          }
          {
            on = "<C-e>";
            run = "config";
            desc = "Open the configuration file";
          }
          {
            on = "u";
            run = "log";
            desc = "Show logs";
          }

          # Help
          {
            on = "?";
            run = "help";
            desc = "Show help";
          }
        ];
      };
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
      select = {
        border = {
          fg = "#${palette.base0D}";
        };
        active = {
          fg = "#${palette.base0E}";
          bold = true;
        };
        inactive = { };
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
            text = "\ue204";
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
