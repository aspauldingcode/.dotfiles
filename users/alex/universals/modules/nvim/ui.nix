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
          "<c-v>" = "jump_vsplit";
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
                  bg = "#${palette.base0E}";
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
                  bg = "#${palette.base0D}";
                  gui = "bold";
                };
              };

              visual = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base0C}";
                  gui = "bold";
                };
              };

              replace = {
                a = {
                  fg = "#${palette.base00}";
                  bg = "#${palette.base08}";
                  gui = "bold";
                };
              };

              inactive = {
                a = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base00}";
                  gui = "bold";
                };
                b = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base00}";
                };
                c = {
                  fg = "#${palette.base05}";
                  bg = "#${palette.base00}";
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

            lualine_c = [ "lsp_progress" ];

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

    # Status column
    statuscol = {
      enable = true;
      settings = {
        segments = [
          {
            text = [ "%s" ];
            click = "v:lua.ScSa";
          }
          {
            text = [ { __raw = "function(args) return require('statuscol.builtin').lnumfunc(args) end"; } ];
            click = "v:lua.ScLa";
          }
          {
            text = [
              " "
              { __raw = "require('statuscol.builtin').foldfunc"; }
              " "
            ];
            condition = [
              { __raw = "require('statuscol.builtin').not_empty"; }
              true
              { __raw = "require('statuscol.builtin').not_empty"; }
            ];
            click = "v:lua.ScFa";
          }
        ];
        clickmod = "c";
        clickhandlers = {
          Lnum = "require('statuscol.builtin').lnum_click";
          FoldClose = "require('statuscol.builtin').foldclose_click";
          FoldOpen = "require('statuscol.builtin').foldopen_click";
          FoldOther = "require('statuscol.builtin').foldother_click";
          DapBreakpointRejected = "require('statuscol.builtin').toggle_breakpoint";
          DapBreakpoint = "require('statuscol.builtin').toggle_breakpoint";
          DapBreakpointCondition = "require('statuscol.builtin').toggle_breakpoint";
          DiagnosticSignError = "require('statuscol.builtin').diagnostic_click";
          DiagnosticSignHint = "require('statuscol.builtin').diagnostic_click";
          DiagnosticSignInfo = "require('statuscol.builtin').diagnostic_click";
          DiagnosticSignWarn = "require('statuscol.builtin').diagnostic_click";
          GitSignsTopdelete = "require('statuscol.builtin').gitsigns_click";
          GitSignsUntracked = "require('statuscol.builtin').gitsigns_click";
          GitSignsAdd = "require('statuscol.builtin').gitsigns_click";
          GitSignsChange = "require('statuscol.builtin').gitsigns_click";
          GitSignsChangedelete = "require('statuscol.builtin').gitsigns_click";
          GitSignsDelete = "require('statuscol.builtin').gitsigns_click";
          gitsigns_extmark_signs_ = "require('statuscol.builtin').gitsigns_click";
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

    # Folding
    nvim-ufo = {
      enable = true;
      package = pkgs.unstable.vimPlugins.nvim-ufo;
      settings = {
        enable_get_fold_virt_text = true;
        close_fold_kinds_for_ft = {
          imports = true;
          comment = true;
        };
        fold_virt_text_handler = ''
          function(virtText, lnum, endLnum, width, truncate)
            local newVirtText = {}
            local suffix = ('  %d '):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
              local chunkText = chunk[1]
              local chunkWidth = vim.fn.strdisplaywidth(chunkText)
              if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
              else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, {chunkText, hlGroup})
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if curWidth + chunkWidth < targetWidth then
                  suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                end
                break
              end
              curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, {suffix, 'MoreMsg'})
            return newVirtText
          end
        '';
        open_fold_hl_timeout = 300;
        provider_selector = "function(bufnr, filetype, buftype) return {'treesitter', 'indent'} end";
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
          highlight = null;
          show_exact_scope = true;
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
}
