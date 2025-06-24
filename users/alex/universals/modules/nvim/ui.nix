{ config, pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Diagnostics display
    trouble = {
      enable = true;
      settings = {
        # Basic v3 configuration
        auto_close = false;
        auto_open = false;
        auto_preview = true;
        auto_refresh = true;
        auto_jump = false;
        focus = false;
        restore = true;
        follow = true;
        indent_guides = true;
        max_items = 200;
        multiline = true;
        pinned = false;
        warn_no_results = true;
        open_no_results = false;

        # Window configuration
        win = {
          type = "split";
          position = "bottom";
          size = 10;
        };

        # Preview window
        preview = {
          type = "main";
          scratch = true;
        };

        # Key mappings (v3 style)
        keys = {
          "?" = "help";
          "r" = "refresh";
          "R" = "toggle_refresh";
          "q" = "close";
          "o" = "jump_close";
          "<esc>" = "cancel";
          "<cr>" = "jump";
          "<2-leftmouse>" = "jump";
          "<c-s>" = "jump_split";
          "<c-t>" = "jump_vsplit";
          "}" = "next";
          "]]" = "next";
          "{" = "prev";
          "[[" = "prev";
          "dd" = "delete";
          "d" = {
            action = "delete";
            mode = "v";
          };
          "i" = "inspect";
          "p" = "preview";
          "P" = "toggle_preview";
          "zo" = "fold_open";
          "zO" = "fold_open_recursive";
          "zc" = "fold_close";
          "zC" = "fold_close_recursive";
          "za" = "fold_toggle";
          "zA" = "fold_toggle_recursive";
          "zm" = "fold_more";
          "zM" = "fold_close_all";
          "zr" = "fold_reduce";
          "zR" = "fold_open_all";
          "zx" = "fold_update";
          "zX" = "fold_update_all";
          "zn" = "fold_disable";
          "zN" = "fold_enable";
          "zi" = "fold_toggle_enable";
        };

        # Icons configuration (v3 style)
        icons = {
          indent = {
            top = "│ ";
            middle = "├╴";
            last = "└╴";
            fold_open = " ";
            fold_closed = " ";
            ws = "  ";
          };
          folder_closed = " ";
          folder_open = " ";
          kinds = {
            Array = " ";
            Boolean = "󰨙 ";
            Class = " ";
            Constant = "󰏿 ";
            Constructor = " ";
            Enum = " ";
            EnumMember = " ";
            Event = " ";
            Field = " ";
            File = " ";
            Function = "󰊕 ";
            Interface = " ";
            Key = " ";
            Method = "󰊕 ";
            Module = " ";
            Namespace = "󰦮 ";
            Null = " ";
            Number = "󰎠 ";
            Object = " ";
            Operator = " ";
            Package = " ";
            Property = " ";
            String = " ";
            Struct = "󰆼 ";
            TypeParameter = " ";
            Variable = "󰀫 ";
          };
        };
      };
    };

    # Notifications
    notify = {
      enable = true;
      package = pkgs.vimPlugins.nvim-notify;
      settings = {
        extraOptions = { };
        fps = 30;
        level = null;
        max_height = 20;
        max_width = 80;
        minimum_width = 20;
        on_close = null;
        on_open = null;
        render = "compact";
        stages = "fade";
        timeout = 2000;
        top_down = true;
        icons = {
          debug = "";
          error = "";
          info = "";
          trace = "✎";
          warn = "";
        };
      };
    };

    # Status line
    lualine =
      let
        inherit (config.colorScheme) palette;
      in
      {
        enable = true;
        settings = {
          options = {
            component_separators = "";
            section_separators = {
              left = "";
              right = "";
            };

            theme = {
              normal = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base0D}"; # Blue for normal mode
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base02}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base01}";
                };
              };

              insert = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base0B}"; # Green for insert mode
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base02}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base01}";
                };
              };

              visual = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base0E}"; # Purple for all visual modes
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base02}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base01}";
                };
              };

              replace = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base08}"; # Red for replace mode
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base02}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base01}";
                };
              };

              command = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base04}"; # Gray for command mode
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base02}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base01}";
                };
              };

              inactive = {
                a = {
                  fg = "#${palette.base04}";
                  bg = "#${palette.base01}";
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base04}";
                  bg = "#${palette.base01}";
                };
                c = {
                  fg = "#${palette.base04}";
                  bg = "#${palette.base01}";
                };
              };
            };
          };

          sections = {
            lualine_a = [
              {
                __raw = ''
                  {
                    "mode",
                    separator = { left = "" },
                    right_padding = 2,
                  }
                '';
              }
            ];

            lualine_c = [
              {
                __raw = ''
                  {
                    function()
                      return require('lsp-status').status()
                    end,
                  }
                '';
              }
            ];

            lualine_x = [
              "encoding"
              "fileformat"
              "filetype"
              {
                __raw = ''
                  {
                    function()
                      -- Check actual Copilot authentication status
                      local copilot_ok, copilot = pcall(require, 'copilot.client')
                      if copilot_ok and copilot then
                        -- Check if Copilot is authenticated and running
                        if copilot.is_disabled and not copilot.is_disabled() then
                          return "󰄬"  -- Checkmark icon when authenticated
                        end
                      end
                      return "󰅖"  -- X icon when not authenticated
                    end,
                    color = function()
                      -- Check Copilot authentication status for color
                      local copilot_ok, copilot = pcall(require, 'copilot.client')
                      if copilot_ok and copilot then
                        -- Check if Copilot is authenticated and enabled
                        if copilot.is_disabled and not copilot.is_disabled() then
                          return { bg = "#${palette.base0B}", fg = "#${palette.base00}", gui = "bold" }  -- Green background
                        end
                      end
                      return { bg = "#${palette.base08}", fg = "#${palette.base00}", gui = "bold" }  -- Red background
                    end,
                    on_click = function()
                      vim.cmd("Copilot status")
                    end,
                  }
                '';
              }
            ];

            lualine_z = [
              {
                __raw = ''
                  {
                    "location",
                    separator = { right = "" },
                    left_padding = 2,
                  }
                '';
              }
            ];
          };
        };
      };

    # Status column with beautiful fold icons
    statuscol = {
      enable = true;
      settings = {
        # Custom segments with fold icons after line numbers
        segments = [
          # Line numbers
          {
            text = [
              {
                __raw = "require('statuscol.builtin').lnumfunc";
              }
              " "
            ];
            condition = [
              true
              {
                __raw = "require('statuscol.builtin').not_empty";
              }
            ];
            click = "v:lua.ScLa";
          }
          # Git signs and diagnostics (between line numbers and fold icons)
          {
            text = [ "%s" ];
            click = "v:lua.ScSa";
          }
          # Beautiful fold column with modern icons (after git signs)
          {
            text = [
              {
                __raw = ''
                  function(args)
                    local foldclosed = vim.fn.foldclosed(args.lnum)
                    local foldlevel = vim.fn.foldlevel(args.lnum)

                    if foldlevel == 0 then
                      return " "
                    end

                    -- Only show icon on the first line of a fold
                    if foldlevel > vim.fn.foldlevel(args.lnum - 1) then
                      if foldclosed == -1 then
                        return "" -- bigger open fold icon
                      else
                        return "" -- bigger closed fold icon
                      end
                    end

                    return " "
                  end
                '';
              }
            ];
            click = "v:lua.ScFa";
            hl = "FoldColumn";
          }
        ];

        # Custom click handlers for proper fold toggling
        clickhandlers = {
          Diagnostic = {
            __raw = ''
              function(args)
                local line = args.mousepos.line
                local diagnostics = vim.diagnostic.get(0, { lnum = line - 1 })

                if #diagnostics > 0 then
                  vim.diagnostic.open_float({
                    bufnr = 0,
                    pos = line - 1,
                    scope = "line",
                    border = "rounded",
                    source = "always",
                    prefix = function(diagnostic, i, total)
                      local icons = {
                        [vim.diagnostic.severity.ERROR] = "󰅚",
                        [vim.diagnostic.severity.WARN] = "󰀪",
                        [vim.diagnostic.severity.HINT] = "󰌶",
                        [vim.diagnostic.severity.INFO] = "",
                      }
                      return string.format("%s ", icons[diagnostic.severity] or "")
                    end,
                  })
                end
              end
            '';
          };
          FoldClose = {
            __raw = ''
              function(args)
                local lnum = args.mousepos.line
                if vim.fn.foldclosed(lnum) ~= -1 then
                  vim.cmd(lnum .. "foldopen")
                end
              end
            '';
          };
          FoldOpen = {
            __raw = ''
              function(args)
                local lnum = args.mousepos.line
                if vim.fn.foldclosed(lnum) == -1 then
                  vim.cmd(lnum .. "foldclose")
                end
              end
            '';
          };
          FoldOther = {
            __raw = ''
              function(args)
                local lnum = args.mousepos.line
                -- Toggle fold regardless of current state
                if vim.fn.foldlevel(lnum) > 0 then
                  if vim.fn.foldclosed(lnum) == -1 then
                    vim.cmd(lnum .. "foldclose")
                  else
                    vim.cmd(lnum .. "foldopen")
                  end
                end
              end
            '';
          };
        };
      };
    };

    # File tree
    nvim-tree = {
      enable = true;
      autoClose = false;
      autoReloadOnWrite = null;
      disableNetrw = null;
      extraOptions = { };
      hijackCursor = null;
      hijackNetrw = null;
      hijackUnnamedBufferWhenOpening = null;
      ignoreBufferOnSetup = false;
      ignoreFtOnSetup = [ ];
      onAttach = null;
      openOnSetup = true;
      openOnSetupFile = false;
      preferStartupRoot = null;
      reloadOnBufenter = null;
      respectBufCwd = null;
      rootDirs = null;
      selectPrompts = null;
      sortBy = null;
      syncRootWithCwd = null;
      git = {
        enable = true;
        ignore = true;
        showOnDirs = true;
        showOnOpenDirs = true;
        timeout = 400;
      };
    };

    # Buffer tabs
    bufferline.enable = true;

    # Startup screen
    startup.enable = false;
    startify = {
      enable = true;
      settings = {
        change_to_dir = false;
        custom_header = [
          ""
          "     ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
          "     ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
          "     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
          "     ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
          "     ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
          "     ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
        ];
        fortune_use_unicode = true;
        lists = [
          {
            type = "files";
            header = [ "   MRU" ];
          }
          {
            type = "dir";
            header = [ { __raw = "'   MRU' .. vim.loop.cwd()"; } ];
          }
          {
            type = "sessions";
            header = [ "   Sessions" ];
          }
          {
            type = "bookmarks";
            header = [ "   Bookmarks" ];
          }
          {
            type = "commands";
            header = [ "   Commands" ];
          }
        ];
      };
    };

    # Visual enhancements
    web-devicons.enable = true;
    colorizer.enable = true; # color previews
    noice.settings.lsp.progress.enabled = true;

    # Origami - Enhanced fold management (replaces nvim-ufo)
    origami = {
      enable = true;
      settings = {
        # Use LSP for folding with treesitter as fallback (v2.0+ default)
        useLspFoldsWithTreesitterFallback = true;
        # Pause folds while searching
        pauseFoldsOnSearch = true;
        # Enhanced fold text with decorations
        foldtext = {
          enabled = true;
          padding = 3;
          lineCount = {
            template = "%d lines";
            hlgroup = "Comment";
          };
          diagnosticsCount = true;
          gitsignsCount = true;
        };
        # Auto-fold comments and imports
        autoFold = {
          enabled = true;
          kinds = [
            "comment"
            "imports"
          ];
        };
        # Disable built-in fold keymaps (we set up custom ones)
        foldKeymaps = {
          setup = false;
          hOnlyOpensOnFirstColumn = false;
        };
      };
    };

    # Indentation guides
    indent-blankline = {
      enable = true;
      settings = {
        exclude = {
          buftypes = [
            "terminal"
            "nofile"
            "quickfix"
            "prompt"
          ];
          filetypes = [
            "lspinfo"
            "packer"
            "checkhealth"
            "help"
            "man"
            "gitcommit"
            "TelescopePrompt"
            "TelescopeResults"
            "''"
            "nvimtree"
            "startify"
            "dashboard"
          ];
        };
        indent = {
          char = "▏";
          tab_char = null;
          highlight = null;
        };
        scope = {
          enabled = true;
          char = null;
          highlight = [
            "IndentBlanklineScope1"
            "IndentBlanklineScope2"
            "IndentBlanklineScope3"
          ];
          show_exact_scope = true;
          show_start = true;
        };
        whitespace = {
          highlight = null;
          remove_blankline_trail = true;
        };
      };
    };

    # Commenting
    comment = {
      enable = true;
      settings.opleader.line = if pkgs.stdenv.isDarwin then "<D-/>" else "<C-/>";
    };

    # Mini modules (without animations)
    mini = {
      enable = true;
      modules = {
        # No animate module - removed earlier
      };
    };
  };

  programs.nixvim.extraConfigLua = ''
    vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#${config.colorScheme.palette.base07}" })

    -- Enhanced diagnostic display on hover/click
    vim.api.nvim_create_autocmd("CursorHold", {
      callback = function()
        local opts = {
          focusable = false,
          close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
          border = "rounded",
          source = "always",
          prefix = function(diagnostic, i, total)
            local icons = {
              [vim.diagnostic.severity.ERROR] = "󰅚",
              [vim.diagnostic.severity.WARN] = "󰀪",
              [vim.diagnostic.severity.HINT] = "󰌶",
              [vim.diagnostic.severity.INFO] = "",
            }
            return string.format("%s ", icons[diagnostic.severity] or "")
          end,
        }
        vim.diagnostic.open_float(nil, opts)
      end
    })

    -- Listen for lsp-status events and refresh lualine
    vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = "lualine_augroup",
      pattern = "LspStatusUpdate",
      callback = function()
        require("lualine").refresh()
      end,
    })
  '';

  programs.nixvim.highlight = {
    FoldColumn = {
      fg = "#${config.colorScheme.palette.base07}";
    };
    IndentBlanklineScope1 = {
      fg = "#${config.colorScheme.palette.base0D}";
    };
    IndentBlanklineScope2 = {
      fg = "#${config.colorScheme.palette.base0A}";
    };
    IndentBlanklineScope3 = {
      fg = "#${config.colorScheme.palette.base0B}";
    };
  };
}
