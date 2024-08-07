{ config, pkgs, ... }:

# yazi configuration!
# FIXME: why is yazi broken on nixos? 
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
            run = "${"EDITOR:=nvim"} \"$@\"";
            desc = "$EDITOR";
            block = true;
            for = "unix";
          }
          {
            run = "code \"%*\"";
            orphan = true;
            desc = "code";
            for = "windows";
          }
          {
            run = "code -w \"%*\"";
            block = true;
            desc = "code (block)";
            for = "windows";
          }
        ];
        open = [
          {
            run = "xdg-open \"$@\"";
            desc = "Open";
            for = "linux";
          }
          {
            run = "open \"$@\"";
            desc = "Open";
            for = "macos";
          }
          {
            run = "start \"\" \"%1\"";
            orphan = true;
            desc = "Open";
            for = "windows";
          }
        ];
        reveal = [
          {
            run = "open -R \"$1\"";
            desc = "Reveal";
            for = "macos";
          }
          {
            run = "explorer /select, \"%1\"";
            orphan = true;
            desc = "Reveal";
            for = "windows";
          }
          {
            run = "exiftool \"$1\"; echo \"Press enter to exit\"; read _";
            block = true;
            desc = "Show EXIF";
            for = "unix";
          }
        ];
        extract = [
          {
            run = "unar \"$1\"";
            desc = "Extract here";
            for = "unix";
          }
          {
            run = "unar \"%1\"";
            desc = "Extract here";
            for = "windows";
          }
        ];
        play = [
          {
            run = "mpv \"$@\"";
            orphan = true;
            for = "unix";
          }
          {
            run = "mpv \"%1\"";
            orphan = true;
            for = "windows";
          }
          {
            run = "mediainfo \"$1\"; echo \"Press enter to exit\"; read _";
            block = true;
            desc = "Show media info";
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

        create_title = "Create:";
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

        quit_title = "{n} task{s} runnning, sure to quit? (y/N)";
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
          fg = "cyan";
        };
        hovered = {
          reversed = true;
        };
        preview_hovered = {
          underline = true;
        };
        find_keyword = {
          fg = "yellow";
          bold = true;
          italic = true;
          underline = true;
        };
        find_position = {
          fg = "magenta";
          bg = "reset";
          bold = true;
          italic = true;
        };
        marker_copied = {
          fg = "lightgreen";
          bg = "lightgreen";
        };
        marker_cut = {
          fg = "lightred";
          bg = "lightred";
        };
        marker_marked = {
          fg = "lightcyan";
          bg = "lightcyan";
        };
        marker_selected = {
          fg = "lightyellow";
          bg = "lightyellow";
        };
        tab_active = {
          reversed = true;
        };
        tab_inactive = { };
        tab_width = 1;
        count_copied = {
          fg = "white";
          bg = "green";
        };
        count_cut = {
          fg = "white";
          bg = "red";
        };
        count_selected = {
          fg = "white";
          bg = "yellow";
        };
        border_symbol = "│";
        border_style = {
          fg = "gray";
        };
        syntect_theme = "";
      };
      status = {
        separator_open = "\ue0b6";
        separator_close = "\ue0b4";
        separator_style = {
          fg = "gray";
          bg = "gray";
        };
        mode_normal = {
          bg = "blue";
          bold = true;
        };
        mode_select = {
          bg = "red";
          bold = true;
        };
        mode_unset = {
          bg = "red";
          bold = true;
        };
        progress_label = {
          bold = true;
        };
        progress_normal = {
          fg = "blue";
          bg = "black";
        };
        progress_error = {
          fg = "red";
          bg = "black";
        };
        permissions_t = {
          fg = "green";
        };
        permissions_r = {
          fg = "yellow";
        };
        permissions_w = {
          fg = "red";
        };
        permissions_x = {
          fg = "cyan";
        };
        permissions_s = {
          fg = "darkgray";
        };
      };
      select = {
        border = {
          fg = "blue";
        };
        active = {
          fg = "magenta";
          bold = true;
        };
        inactive = { };
      };
      notify = {
        icon_error = "\uf057";
        icon_info = "\uf05a";
        icon_warn = "\uf071";
        title_error = {
          fg = "red";
        };
        title_info = {
          fg = "green";
        };
        title_warn = {
          fg = "yellow";
        };
      };
      tasks = {
        border = {
          fg = "blue";
        };
        hovered = {
          fg = "magenta";
          underline = true;
        };
        title = { };
      };
      which = {
        cand = {
          fg = "lightcyan";
        };
        cols = 3;
        desc = {
          fg = "lightmagenta";
        };
        mask = {
          bg = "black";
        };
        rest = {
          fg = "darkgray";
        };
        separator = " \uea9c ";
        separator_style = {
          fg = "darkgray";
        };
      };
      icon = {
        files = [
          {
            name = "ai";
            text = "\uf042";
            fg_dark = "#f0a30a";
            fg_light = "#f0a30a";
          }
          {
            name = "avi";
            text = "\uf0aa";
            fg_dark = "#f0a30a";
            fg_light = "#f0a30a";
          }
          {
            name = "bat";
            text = "\ue795";
            fg_dark = "#4d5a5e";
            fg_light = "#3a4446";
          }
          {
            name = "bin";
            text = "\uf471";
            fg_dark = "#76bbff";
            fg_light = "#418cf0";
          }
          {
            name = "bmp";
            text = "\uf1c5";
            fg_dark = "#b44ac0";
            fg_light = "#7d32a8";
          }
          {
            name = "c";
            text = "\ue61e";
            fg_dark = "#00589d";
            fg_light = "#00589d";
          }
          {
            name = "cc";
            text = "\ue61e";
            fg_dark = "#00589d";
            fg_light = "#00589d";
          }
          {
            name = "cl";
            text = "\ue61f";
            fg_dark = "#764da0";
            fg_light = "#764da0";
          }
          {
            name = "cmake";
            text = "\ue61f";
            fg_dark = "#cd3c49";
            fg_light = "#cd3c49";
          }
          {
            name = "cpp";
            text = "\ue61d";
            fg_dark = "#f34b7d";
            fg_light = "#f34b7d";
          }
          {
            name = "cs";
            text = "\uf81a";
            fg_dark = "#68217a";
            fg_light = "#68217a";
          }
          {
            name = "css";
            text = "\uf13c";
            fg_dark = "#563d7c";
            fg_light = "#563d7c";
          }
          {
            name = "csv";
            text = "\uf021";
            fg_dark = "#e28b00";
            fg_light = "#e28b00";
          }
          {
            name = "d";
            text = "\uf1c0";
            fg_dark = "#00589d";
            fg_light = "#00589d";
          }
          {
            name = "dart";
            text = "\ueae5";
            fg_dark = "#0175c2";
            fg_light = "#0175c2";
          }
          {
            name = "db";
            text = "\uf1c0";
            fg_dark = "#ffcb00";
            fg_light = "#ffcb00";
          }
          {
            name = "desktop";
            text = "\ue79e";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "diff";
            text = "\uf068";
            fg_dark = "#e34c26";
            fg_light = "#e34c26";
          }
          {
            name = "doc";
            text = "\uf1c2";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "docx";
            text = "\uf1c2";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "drawio";
            text = "\uf0b1";
            fg_dark = "#e16547";
            fg_light = "#e16547";
          }
          {
            name = "dropbox";
            text = "\uf16b";
            fg_dark = "#007ee5";
            fg_light = "#007ee5";
          }
          {
            name = "eex";
            text = "\ue60e";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "elm";
            text = "\ue62c";
            fg_dark = "#60b5cc";
            fg_light = "#60b5cc";
          }
          {
            name = "eot";
            text = "\uf031";
            fg_dark = "#f06e99";
            fg_light = "#f06e99";
          }
          {
            name = "epub";
            text = "\ue600";
            fg_dark = "#3d59a1";
            fg_light = "#3d59a1";
          }
          {
            name = "erb";
            text = "\ue21e";
            fg_dark = "#701516";
            fg_light = "#701516";
          }
          {
            name = "erl";
            text = "\ue60e";
            fg_dark = "#b83998";
            fg_light = "#b83998";
          }
          {
            name = "ex";
            text = "\ue60d";
            fg_dark = "#6e4a7e";
            fg_light = "#6e4a7e";
          }
          {
            name = "exs";
            text = "\ue60d";
            fg_dark = "#6e4a7e";
            fg_light = "#6e4a7e";
          }
          {
            name = "f#";
            text = "\ue7a7";
            fg_dark = "#378bba";
            fg_light = "#378bba";
          }
          {
            name = "favicon";
            text = "\uf007";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "fish";
            text = "\uf489";
            fg_dark = "#4aadcf";
            fg_light = "#4aadcf";
          }
          {
            name = "flac";
            text = "\uf001";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "fsharp";
            text = "\ue7a7";
            fg_dark = "#378bba";
            fg_light = "#378bba";
          }
          {
            name = "gdoc";
            text = "\uf1c2";
            fg_dark = "#4285f4";
            fg_light = "#4285f4";
          }
          {
            name = "gemfile";
            text = "\ue21e";
            fg_dark = "#701516";
            fg_light = "#701516";
          }
          {
            name = "gif";
            text = "\uf1c5";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "go";
            text = "\ue626";
            fg_dark = "#375eab";
            fg_light = "#375eab";
          }
          {
            name = "godot";
            text = "\ue7a8";
            fg_dark = "#7d91d0";
            fg_light = "#7d91d0";
          }
          {
            name = "gruntfile";
            text = "\ue21e";
            fg_dark = "#fba919";
            fg_light = "#fba919";
          }
          {
            name = "gz";
            text = "\uf410";
            fg_dark = "#e44b23";
            fg_light = "#e44b23";
          }
          {
            name = "h";
            text = "\ue61e";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "hpp";
            text = "\ue61d";
            fg_dark = "#f34b7d";
            fg_light = "#f34b7d";
          }
          {
            name = "hs";
            text = "\ue777";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "html";
            text = "\uf13b";
            fg_dark = "#e34c26";
            fg_light = "#e34c26";
          }
          {
            name = "ico";
            text = "\uf1c5";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "java";
            text = "\ue204";
            fg_dark = "#b07219";
            fg_light = "#b07219";
          }
          {
            name = "jpg";
            text = "\uf1c5";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "jpeg";
            text = "\uf1c5";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "json";
            text = "\ue60b";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "jsx";
            text = "\ue7ba";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "key";
            text = "\uf084";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "kts";
            text = "\ue628";
            fg_dark = "#f18e33";
            fg_light = "#f18e33";
          }
          {
            name = "less";
            text = "\ue749";
            fg_dark = "#438eff";
            fg_light = "#438eff";
          }
          {
            name = "lock";
            text = "\uf023";
            fg_dark = "#ffca28";
            fg_light = "#ffca28";
          }
          {
            name = "lua";
            text = "\ue620";
            fg_dark = "#000080";
            fg_light = "#000080";
          }
          {
            name = "m";
            text = "\uf095";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "markdown";
            text = "\uf48a";
            fg_dark = "#083fa1";
            fg_light = "#083fa1";
          }
          {
            name = "md";
            text = "\uf48a";
            fg_dark = "#083fa1";
            fg_light = "#083fa1";
          }
          {
            name = "mdx";
            text = "\uf48a";
            fg_dark = "#083fa1";
            fg_light = "#083fa1";
          }
          {
            name = "mov";
            text = "\uf03d";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "mp3";
            text = "\uf001";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "mp4";
            text = "\uf03d";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "nix";
            text = "\ue779";
            fg_dark = "#7d4e4e";
            fg_light = "#7d4e4e";
          }
          {
            name = "node_modules";
            text = "\ue718";
            fg_dark = "#00a8cc";
            fg_light = "#00a8cc";
          }
          {
            name = "npmignore";
            text = "\ue71e";
            fg_dark = "#cb3837";
            fg_light = "#cb3837";
          }
          {
            name = "npmrc";
            text = "\ue71e";
            fg_dark = "#cb3837";
            fg_light = "#cb3837";
          }
          {
            name = "odt";
            text = "\uf1c2";
            fg_dark = "#ffcc00";
            fg_light = "#ffcc00";
          }
          {
            name = "opus";
            text = "\uf001";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "otf";
            text = "\uf031";
            fg_dark = "#000000";
            fg_light = "#000000";
          }
          {
            name = "pdf";
            text = "\uf1c1";
            fg_dark = "#e34c26";
            fg_light = "#e34c26";
          }
          {
            name = "php";
            text = "\ue73d";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "png";
            text = "\uf1c5";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "ppt";
            text = "\uf1c4";
            fg_dark = "#cb4a32";
            fg_light = "#cb4a32";
          }
          {
            name = "pptx";
            text = "\uf1c4";
            fg_dark = "#cb4a32";
            fg_light = "#cb4a32";
          }
          {
            name = "procfile";
            text = "\ue21e";
            fg_dark = "#6a737d";
            fg_light = "#6a737d";
          }
          {
            name = "py";
            text = "\ue606";
            fg_dark = "#ffbc03";
            fg_light = "#ffbc03";
          }
          {
            name = "pyc";
            text = "\ue606";
            fg_dark = "#ffe873";
            fg_light = "#ffe873";
          }
          {
            name = "pyo";
            text = "\ue606";
            fg_dark = "#ffe873";
            fg_light = "#ffe873";
          }
          {
            name = "r";
            text = "\uf25d";
            fg_dark = "#198ce7";
            fg_light = "#198ce7";
          }
          {
            name = "rakefile";
            text = "\ue21e";
            fg_dark = "#701516";
            fg_light = "#701516";
          }
          {
            name = "rb";
            text = "\ue21e";
            fg_dark = "#701516";
            fg_light = "#701516";
          }
          {
            name = "rs";
            text = "\ue7a8";
            fg_dark = "#dea584";
            fg_light = "#dea584";
          }
          {
            name = "rss";
            text = "\uf09e";
            fg_dark = "#fb9d18";
            fg_light = "#fb9d18";
          }
          {
            name = "rtf";
            text = "\uf1c2";
            fg_dark = "#b07219";
            fg_light = "#b07219";
          }
          {
            name = "sass";
            text = "\ue603";
            fg_dark = "#cb6699";
            fg_light = "#cb6699";
          }
          {
            name = "scss";
            text = "\ue603";
            fg_dark = "#cb6699";
            fg_light = "#cb6699";
          }
          {
            name = "sh";
            text = "\uf489";
            fg_dark = "#4d5a5e";
            fg_light = "#4d5a5e";
          }
          {
            name = "slim";
            text = "\ue73b";
            fg_dark = "#e34c26";
            fg_light = "#e34c26";
          }
          {
            name = "sql";
            text = "\ue706";
            fg_dark = "#dad8d8";
            fg_light = "#dad8d8";
          }
          {
            name = "sqlite3";
            text = "\ue706";
            fg_dark = "#dad8d8";
            fg_light = "#dad8d8";
          }
          {
            name = "styl";
            text = "\ue600";
            fg_dark = "#b3d107";
            fg_light = "#b3d107";
          }
          {
            name = "sublime-package";
            text = "\uf0f6";
            fg_dark = "#e37933";
            fg_light = "#e37933";
          }
          {
            name = "sublime-settings";
            text = "\uf0f6";
            fg_dark = "#e37933";
            fg_light = "#e37933";
          }
          {
            name = "svg";
            text = "\uf1c5";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "swift";
            text = "\ue755";
            fg_dark = "#f05138";
            fg_light = "#f05138";
          }
          {
            name = "tar";
            text = "\uf410";
            fg_dark = "#b07219";
            fg_light = "#b07219";
          }
          {
            name = "tex";
            text = "\ue600";
            fg_dark = "#3d6117";
            fg_light = "#3d6117";
          }
          {
            name = "ts";
            text = "\ue628";
            fg_dark = "#007acc";
            fg_light = "#007acc";
          }
          {
            name = "tsx";
            text = "\ue7ba";
            fg_dark = "#007acc";
            fg_light = "#007acc";
          }
          {
            name = "ttf";
            text = "\uf031";
            fg_dark = "#000000";
            fg_light = "#000000";
          }
          {
            name = "txt";
            text = "\uf15c";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "video";
            text = "\uf03d";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "vue";
            text = "\ue62d";
            fg_dark = "#42b883";
            fg_light = "#42b883";
          }
          {
            name = "webp";
            text = "\uf1c5";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "xls";
            text = "\uf1c3";
            fg_dark = "#207245";
            fg_light = "#207245";
          }
          {
            name = "xlsx";
            text = "\uf1c3";
            fg_dark = "#207245";
            fg_light = "#207245";
          }
          {
            name = "xml";
            text = "\uf1c4";
            fg_dark = "#00599d";
            fg_light = "#00599d";
          }
          {
            name = "yarn.lock";
            text = "\ue718";
            fg_dark = "#2188b6";
            fg_light = "#2188b6";
          }
          {
            name = "yml";
            text = "\uf481";
            fg_dark = "#cb171e";
            fg_light = "#cb171e";
          }
          {
            name = "zip";
            text = "\uf410";
            fg_dark = "#b07219";
            fg_light = "#b07219";
          }
        ];
        directories = [
          {
            name = ".config";
            text = "\uf423";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = ".git";
            text = "\ue5fb";
            fg_dark = "#f14e32";
            fg_light = "#f14e32";
          }
          {
            name = ".github";
            text = "\uf7b2";
            fg_dark = "#24292f";
            fg_light = "#24292f";
          }
          {
            name = ".gitignore";
            text = "\ue702";
            fg_dark = "#e84d31";
            fg_light = "#e84d31";
          }
          {
            name = ".npmignore";
            text = "\ue71e";
            fg_dark = "#cb3837";
            fg_light = "#cb3837";
          }
          {
            name = ".vscode";
            text = "\ue70c";
            fg_dark = "#0078d7";
            fg_light = "#0078d7";
          }
          {
            name = "bin";
            text = "\ue5fc";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "build";
            text = "\ueb2a";
            fg_dark = "#ff7f50";
            fg_light = "#ff7f50";
          }
          {
            name = "ci";
            text = "\uf085";
            fg_dark = "#a74c4c";
            fg_light = "#a74c4c";
          }
          {
            name = "dist";
            text = "\uf78d";
            fg_dark = "#e24329";
            fg_light = "#e24329";
          }
          {
            name = "doc";
            text = "\uf1c2";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "docs";
            text = "\uf7b8";
            fg_dark = "#3d5afe";
            fg_light = "#3d5afe";
          }
          {
            name = "img";
            text = "\uf302";
            fg_dark = "#b07219";
            fg_light = "#b07219";
          }
          {
            name = "include";
            text = "\uf7b8";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "lib";
            text = "\uf7b8";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
          {
            name = "logs";
            text = "\uf70e";
            fg_dark = "#f1e05a";
            fg_light = "#f1e05a";
          }
          {
            name = "node_modules";
            text = "\uf898";
            fg_dark = "#e34c26";
            fg_light = "#e34c26";
          }
          {
            name = "public";
            text = "\uf015";
            fg_dark = "#4caf50";
            fg_light = "#4caf50";
          }
          {
            name = "src";
            text = "\ufb66";
            fg_dark = "#586e75";
            fg_light = "#586e75";
          }
          {
            name = "test";
            text = "\uf490";
            fg_dark = "#a074c4";
            fg_light = "#a074c4";
          }
        ];
      };
    };
  };
}