{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Smooth scrolling (disabled - you wanted animations removed)
    neoscroll.enable = false;

    # Enhanced text objects and motions
    # targets.enable = true; # Not available as nixvim plugin option
    vim-surround.enable = true; # Surround text objects with quotes, brackets, etc.

    # Better search and replace
    spectre = {
      enable = true;
      settings = {
        color_devicons = true;
        open_cmd = "vnew";
        live_update = false;
        line_sep_start = "┌─────────────────────────────────────────";
        result_padding = "│  ";
        line_sep = "└─────────────────────────────────────────";
        highlight = {
          ui = "String";
          search = "DiffChange";
          replace = "DiffDelete";
        };
        mapping = {
          "toggle_line" = {
            map = "dd";
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>";
            desc = "toggle current item";
          };
          "enter_file" = {
            map = "<cr>";
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>";
            desc = "goto current file";
          };
          "send_to_qf" = {
            map = "<leader>q";
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>";
            desc = "send all item to quickfix";
          };
          "replace_cmd" = {
            map = "<leader>c";
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>";
            desc = "input replace vim command";
          };
          "show_option_menu" = {
            map = "<leader>o";
            cmd = "<cmd>lua require('spectre').show_options()<CR>";
            desc = "show option";
          };
          "run_current_replace" = {
            map = "<leader>rc";
            cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>";
            desc = "replace current line";
          };
          "run_replace" = {
            map = "<leader>R";
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>";
            desc = "replace all";
          };
          "change_view_mode" = {
            map = "<leader>v";
            cmd = "<cmd>lua require('spectre').change_view()<CR>";
            desc = "change result view mode";
          };
          "change_replace_sed" = {
            map = "trs";
            cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>";
            desc = "use sed to replace";
          };
          "change_replace_oxi" = {
            map = "tro";
            cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>";
            desc = "use oxi to replace";
          };
          "toggle_live_update" = {
            map = "tu";
            cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>";
            desc = "update change when vim write file.";
          };
          "toggle_ignore_case" = {
            map = "ti";
            cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>";
            desc = "toggle ignore case";
          };
          "toggle_ignore_hidden" = {
            map = "th";
            cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>";
            desc = "toggle search hidden";
          };
          "resume_last_search" = {
            map = "<leader>l";
            cmd = "<cmd>lua require('spectre').resume_last_search()<CR>";
            desc = "resume last search before close";
          };
        };
        find_engine = {
          rg = {
            cmd = "rg";
            args = [
              "--color=never"
              "--no-heading"
              "--with-filename"
              "--line-number"
              "--column"
            ];
            options = {
              "ignore-case" = {
                value = "--ignore-case";
                icon = "[I]";
                desc = "ignore case";
              };
              "hidden" = {
                value = "--hidden";
                desc = "hidden file";
                icon = "[H]";
              };
            };
          };
        };
        replace_engine = {
          sed = {
            cmd = "sed";
            args = null;
            options = {
              "ignore-case" = {
                value = "--ignore-case";
                icon = "[I]";
                desc = "ignore case";
              };
            };
          };
        };
        default = {
          find = {
            cmd = "rg";
            options = [ "ignore-case" ];
          };
          replace = {
            cmd = "sed";
          };
        };
      };
    };

    # Multi-cursor support
    visual-multi.enable = true; # Multi-cursor editing support

    # Session management
    auto-session = {
      enable = true;
      settings = {
        log_level = "error";
        auto_session_suppress_dirs = [
          "~/"
          "~/Projects"
          "~/Downloads"
          "/"
        ];
        auto_session_use_git_branch = false;
        auto_session_enable_last_session = false;
        auto_session_root_dir = {
          __raw = ''vim.fn.stdpath("data") .. "/sessions/"'';
        };
        auto_session_enabled = true;
        auto_save_enabled = true;
        auto_restore_enabled = true;
        auto_session_create_enabled = true;
        # Let vim-autoswap handle swap files instead of session management
        bypass_session_save_file_types = [
          "gitcommit"
          "gitrebase"
        ];
      };
    };

    # Highlight word under cursor
    illuminate = {
      enable = true;
      underCursor = true;
      filetypesDenylist = [
        "dirbuf"
        "dirvish"
        "fugitive"
        "NvimTree"
        "Trouble"
      ];
      minCountToHighlight = 2;
    };

    # Better folding - pretty-fold not available as nixvim plugin
    # Using built-in folding with custom configuration instead

    # Undo tree visualization
    undotree = {
      enable = true;
      settings = {
        WindowLayout = 3;
        ShortIndicators = 1;
        DiffpanelHeight = 10;
        DiffAutoOpen = 1;
        SetFocusWhenToggle = 1;
        TreeNodeShape = "*";
        TreeVertShape = "|";
        TreeSplitShape = "/";
        TreeReturnShape = "\\";
        DiffCommand = "diff";
        RelativeTimestamp = 1;
        HighlightChangedText = 1;
        HighlightChangedWithSign = 1;
        HighlightSyntaxAdd = "DiffAdd";
        HighlightSyntaxChange = "DiffChange";
        HighlightSyntaxDel = "DiffDelete";
        HelpLine = 1;
      };
    };

    # Better terminal integration
    toggleterm = {
      enable = true;
      settings = {
        size = 20;
        open_mapping = "[[<c-\\>]]";
        hide_numbers = true;
        shade_filetypes = [ ];
        shade_terminals = true;
        shading_factor = 2;
        start_in_insert = true;
        insert_mappings = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        shell = {
          __raw = "vim.o.shell";
        };
        float_opts = {
          border = "curved";
          winblend = 0;
          highlights = {
            border = "Normal";
            background = "Normal";
          };
        };
      };
    };

    # Project management
    project-nvim = {
      enable = true;
      enableTelescope = true;
      settings = {
        detection_methods = [
          "lsp"
          "pattern"
        ];
        patterns = [
          ".git"
          "_darcs"
          ".hg"
          ".bzr"
          ".svn"
          "Makefile"
          "package.json"
          "flake.nix"
        ];
        ignore_lsp = [ ];
        exclude_dirs = [ ];
        show_hidden = false;
        silent_chdir = true;
        scope_chdir = "global";
        datapath = {
          __raw = ''vim.fn.stdpath("data")'';
        };
      };
    };

    # Zen mode for focused writing
    zen-mode = {
      enable = true;
      settings = {
        window = {
          backdrop = 0.95;
          width = 120;
          height = 1;
          options = {
            signcolumn = "no";
            number = false;
            relativenumber = false;
            cursorline = false;
            cursorcolumn = false;
            foldcolumn = "0";
            list = false;
          };
        };
        plugins = {
          options = {
            enabled = true;
            ruler = false;
            showcmd = false;
            laststatus = 0;
          };
          twilight = {
            enabled = true;
          };
          gitsigns = {
            enabled = false;
          };
          tmux = {
            enabled = false;
          };
        };
      };
    };

    twilight = {
      enable = true;
      settings = {
        dimming = {
          alpha = 0.25;
          color = [
            "Normal"
            "#ffffff"
          ];
          term_bg = "#000000";
          inactive = false;
        };
        context = 10;
        treesitter = true;
        expand = [
          "function"
          "method"
          "table"
          "if_statement"
        ];
        exclude = [ ];
      };
    };
  };

  # Add plugins that aren't available as nixvim plugin options
  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    # nvim-bqf # Better quickfix window - commented out due to config issues
    vim-autoswap # Automatically handle swap file conflicts
  ];

  # Configuration for extra plugins - bqf config commented out due to syntax issues
  # programs.nixvim.extraConfigLua = ''
  #   -- Configure nvim-bqf (Better quickfix window)
  #   -- Configuration commented out due to syntax issues
  # '';

  # Add keymaps for the new plugins
  programs.nixvim.keymaps = [
    # Spectre (search and replace)
    {
      mode = "n";
      key = "<leader>S";
      action = "<cmd>lua require('spectre').toggle()<CR>";
      options.desc = "Toggle Spectre";
    }
    {
      mode = "n";
      key = "<leader>sw";
      action = "<cmd>lua require('spectre').open_visual({select_word=true})<CR>";
      options.desc = "Search current word";
    }
    {
      mode = "v";
      key = "<leader>sw";
      action = "<esc><cmd>lua require('spectre').open_visual()<CR>";
      options.desc = "Search current word";
    }
    {
      mode = "n";
      key = "<leader>sp";
      action = "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>";
      options.desc = "Search on current file";
    }

    # Undotree
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      options.desc = "Toggle undo tree";
    }

    # Zen mode
    {
      mode = "n";
      key = "<leader>zz";
      action = "<cmd>ZenMode<CR>";
      options.desc = "Toggle Zen Mode";
    }

    # Terminal
    {
      mode = "n";
      key = "<leader>tf";
      action = "<cmd>ToggleTerm direction=float<CR>";
      options.desc = "Toggle floating terminal";
    }
    {
      mode = "n";
      key = "<leader>th";
      action = "<cmd>ToggleTerm direction=horizontal<CR>";
      options.desc = "Toggle horizontal terminal";
    }
    {
      mode = "n";
      key = "<leader>tv";
      action = "<cmd>ToggleTerm direction=vertical size=80<CR>";
      options.desc = "Toggle vertical terminal";
    }
  ];

  # Global vim options for folding
  programs.nixvim.opts = {
    # Enable fold column to show clickable fold indicators
    foldcolumn = "1";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;
    # Set fold method to be handled by nvim-ufo
    foldmethod = "manual";
  };
}
