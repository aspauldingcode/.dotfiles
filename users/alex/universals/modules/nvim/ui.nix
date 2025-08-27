{
  config,
  pkgs,
  ...
}:
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
                      -- Check if we have a global LSP progress indicator
                      if _G.lsp_progress_message then
                        local spinners = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }
                        local ms = vim.loop.hrtime() / 1000000
                        local frame = math.floor(ms / 120) % #spinners
                        local spinner = spinners[frame + 1]
                        return spinner .. " " .. _G.lsp_progress_message
                      end
                      return ""
                    end,
                    color = { fg = "#${palette.base0D}" },  -- Blue color for LSP status
                    cond = function()
                      return _G.lsp_progress_message ~= nil and _G.lsp_progress_message ~= ""
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
                      return _G.get_cmdline_hint and _G.get_cmdline_hint() or ""
                    end,
                    color = function()
                      return { fg = "#${palette.base0A}", gui = "italic" }  -- Yellow/orange color for hints
                    end,
                    cond = function()
                      local hint = _G.get_cmdline_hint and _G.get_cmdline_hint() or ""
                      return hint ~= ""
                    end,
                  }
                '';
              }
              {
                __raw = ''
                  {
                    function()
                      return "LSP"
                    end,
                    color = function()
                      local clients = vim.lsp.get_clients({ bufnr = 0 })
                      local has_traditional_lsp = false

                      -- Check for non-LSP-AI clients
                      for _, client in ipairs(clients) do
                        if client.name ~= "lsp_ai" then
                          has_traditional_lsp = true
                          break
                        end
                      end

                      if has_traditional_lsp then
                        return { bg = "#${palette.base02}", fg = "#${palette.base0B}", gui = "bold" }  -- Dark gray bg, green fg when LSP active
                      else
                        return { bg = "#${palette.base02}", fg = "#${palette.base08}", gui = "bold" }  -- Dark gray bg, red fg when no LSP
                      end
                    end,
                    separator = { left = "", right = "" },
                    on_click = function()
                      local clients = vim.lsp.get_clients({ bufnr = 0 })
                      local lines = {}

                      if next(clients) == nil then
                        table.insert(lines, "No LSP clients attached to this buffer")
                        table.insert(lines, "")
                        table.insert(lines, "Filetype: " .. vim.bo.filetype)
                        table.insert(lines, "")
                        table.insert(lines, "Available LSP servers for this filetype:")
                        table.insert(lines, "• Check your lsp.nix configuration")
                        table.insert(lines, "• Ensure LSP servers are installed")
                        table.insert(lines, "• Try :LspStart or :LspRestart")
                      else
                        table.insert(lines, "Active LSP clients for this buffer:")
                        table.insert(lines, "")
                        for _, client in pairs(clients) do
                          -- Skip LSP-AI from this list (it has its own status)
                          if client.name ~= "lsp_ai" then
                            table.insert(lines, "• " .. client.name .. " (ID: " .. client.id .. ")")
                            if client.server_capabilities then
                              local caps = {}
                              if client.server_capabilities.documentFormattingProvider then
                                table.insert(caps, "formatting")
                              end
                              if client.server_capabilities.hoverProvider then
                                table.insert(caps, "hover")
                              end
                              if client.server_capabilities.completionProvider then
                                table.insert(caps, "completion")
                              end
                              if client.server_capabilities.definitionProvider then
                                table.insert(caps, "go-to-def")
                              end
                              if #caps > 0 then
                                table.insert(lines, "  Capabilities: " .. table.concat(caps, ", "))
                              end
                            end
                            table.insert(lines, "")
                          end
                        end

                        -- If no non-LSP-AI clients, show appropriate message
                        if #lines == 2 then -- Only header lines
                          table.insert(lines, "No traditional LSP clients attached")
                          table.insert(lines, "(LSP-AI is handled separately)")
                        end
                      end

                      -- Create popup buffer
                      local buf = vim.api.nvim_create_buf(false, true)
                      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

                      -- Calculate popup size
                      local width = 60
                      local height = math.min(#lines + 2, 15)

                      -- Open popup
                      local win = vim.api.nvim_open_win(buf, true, {
                        relative = 'editor',
                        width = width,
                        height = height,
                        col = (vim.o.columns - width) / 2,
                        row = (vim.o.lines - height) / 2,
                        style = 'minimal',
                        border = 'rounded',
                        title = ' LSP Status ',
                        title_pos = 'center'
                      })

                      -- Set popup keymaps
                      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
                      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<cr>', { noremap = true, silent = true })
                    end,
                  }
                '';
              }
              {
                __raw = ''
                  {
                    function()
                      return "󰧑"  -- AI stars nerd font icon
                    end,
                    color = function()
                      -- Check if cmp-ai is available and API key is set
                      local has_cmp_ai = pcall(require, 'cmp_ai')
                      local api_key = os.getenv("OPENAI_API_KEY")

                      if has_cmp_ai and api_key then
                        return { bg = "#${palette.base01}", fg = "#${palette.base05}", gui = "bold" }  -- Darker gray bg, white fg when ready
                      else
                        return { bg = "#${palette.base01}", fg = "#${palette.base03}", gui = "bold" }  -- Darker gray bg, dark fg when not ready
                      end
                    end,
                    separator = { left = "", right = "" },
                    on_click = function()
                      local has_cmp_ai = pcall(require, 'cmp_ai')
                      local api_key = os.getenv("OPENAI_API_KEY")

                      local lines = {}
                      if has_cmp_ai and api_key then
                        table.insert(lines, "AI Completion: ✓ Ready")
                        table.insert(lines, "Provider: cmp-ai")
                        table.insert(lines, "")
                        table.insert(lines, "Configuration:")
                        table.insert(lines, "• Backend: OpenAI GPT-4o")
                        table.insert(lines, "• Max Lines: 100")
                        table.insert(lines, "• API Key: ✓ Set")
                        table.insert(lines, "• Run on Keystroke: Disabled")
                        table.insert(lines, "")
                        table.insert(lines, "Available keybindings:")
                        table.insert(lines, "• <leader>ag - Trigger AI completion")
                        table.insert(lines, "• <leader>ac - Open AI chat (Avante)")
                        table.insert(lines, "• <leader>at - Check AI status")
                        table.insert(lines, "• <leader>as - Check AI setup")
                        table.insert(lines, "• <C-Space> - Manual completion")
                        table.insert(lines, "")
                        table.insert(lines, "Integration:")
                        table.insert(lines, "• Works directly with nvim-cmp")
                        table.insert(lines, "• Priority: 800 (after LSP)")
                        table.insert(lines, "• Max items: 10")
                      else
                        table.insert(lines, "AI Completion: ✗ Not Ready")
                        table.insert(lines, "")
                        table.insert(lines, "Issues:")
                        if not has_cmp_ai then
                          table.insert(lines, "• cmp-ai plugin not loaded")
                        end
                        if not api_key then
                          table.insert(lines, "• OpenAI API key not set")
                          table.insert(lines, "  Export OPENAI_API_KEY environment variable")
                        end
                        table.insert(lines, "")
                        table.insert(lines, "Setup:")
                        table.insert(lines, "• Provider: OpenAI GPT-4o")
                        table.insert(lines, "• Requires: OPENAI_API_KEY environment variable")
                        table.insert(lines, "• Integration: nvim-cmp source")
                      end

                      -- Create popup buffer
                      local buf = vim.api.nvim_create_buf(false, true)
                      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

                      -- Calculate popup size
                      local width = 55
                      local height = math.min(#lines + 2, 18)

                      -- Open popup
                      local win = vim.api.nvim_open_win(buf, true, {
                        relative = 'editor',
                        width = width,
                        height = height,
                        col = (vim.o.columns - width) / 2,
                        row = (vim.o.lines - height) / 2,
                        style = 'minimal',
                        border = 'rounded',
                        title = ' AI Completion Status ',
                        title_pos = 'center'
                      })

                      -- Set popup keymaps
                      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
                      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<cr>', { noremap = true, silent = true })
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
      ignoreBufferOnSetup = false;
      ignoreFtOnSetup = [ ];
      openOnSetup = true;
      openOnSetupFile = false;
      settings = {
        auto_reload_on_write = null;
        disable_netrw = null;
        hijack_cursor = null;
        hijack_netrw = null;
        hijack_unnamed_buffer_when_opening = null;
        on_attach = {
          __raw = ''
            function(bufnr)
              local api = require("nvim-tree.api")

              -- Default keymaps
              api.config.mappings.default_on_attach(bufnr)

              -- Custom keymap: q to close NvimTree
              vim.keymap.set('n', 'q', api.tree.close, {
                desc = 'Close NvimTree',
                buffer = bufnr,
                noremap = true,
                silent = true,
                nowait = true
              })
            end
          '';
        };
        prefer_startup_root = null;
        reload_on_bufenter = null;
        respect_buf_cwd = null;
        root_dirs = null;
        select_prompts = null;
        sort_by = null;
        sync_root_with_cwd = null;
        git = {
          enable = true;
          ignore = true;
          show_on_dirs = true;
          show_on_open_dirs = true;
          timeout = 400;
        };
      };
    };

    # Buffer tabs - Using barbar instead of bufferline for better colorscheme integration
    barbar = {
      enable = true;
      settings = {
        # barbar automatically respects colorscheme changes
        animation = true;
        auto_hide = false;
        tabpages = true;
        closable = true;
        clickable = true;
        # Focus on close
        focus_on_close = "left";
        # Hide inactive buffers and file extensions
        hide = {
          extensions = false;
          inactive = false;
        };
        # Highlight settings
        highlight_alternate = false;
        highlight_inactive_file_icons = false;
        highlight_visible = true;
        # Icons
        icons = {
          buffer_index = false;
          buffer_number = false;
          button = "×"; # Close button (visible X)
          # Skip diagnostics configuration for now
          filetype = {
            custom_colors = false;
            enabled = true;
          };
          separator = {
            left = "▎";
            right = "";
          };
          modified = {
            button = "●";
          };
          pinned = {
            button = "";
            filename = true;
          };
        };
        # Layout settings
        insert_at_end = false;
        insert_at_start = false;
        maximum_padding = 1;
        minimum_padding = 1;
        maximum_length = 30;
        semantic_letters = true;
        letters = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP";
        no_name_title = "[No Name]";
      };
    };

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
            "Function"
            "Label"
            "Keyword"
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

    -- Initialize global LSP progress tracking
    _G.lsp_progress_message = nil

    -- Helper function to sanitize progress messages
    local function sanitize_message(msg)
      if not msg then return "" end
      -- Replace problematic characters that cause Vim syntax errors
      return msg:gsub("[<>%%]", function(char)
        if char == "<" then return "‹"
        elseif char == ">" then return "›"
        elseif char == "%" then return "%%"
        end
        return char
      end)
    end

    -- Listen for LSP progress events and refresh lualine
    vim.api.nvim_create_augroup("lualine_augroup", { clear = true })

    -- Handle LSP progress events
    vim.api.nvim_create_autocmd("LspProgress", {
      group = "lualine_augroup",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
          return
        end

        local value = args.data.params.value
        if value.kind == "begin" then
          local title = sanitize_message(value.title or "Working...")
          _G.lsp_progress_message = client.name .. ": " .. title
        elseif value.kind == "report" then
          local message = sanitize_message(value.message or value.title or "Working...")
          if value.percentage then
            _G.lsp_progress_message = client.name .. ": " .. message .. " (" .. value.percentage .. "%%)"
          else
            _G.lsp_progress_message = client.name .. ": " .. message
          end
        elseif value.kind == "end" then
          _G.lsp_progress_message = nil
        end

        -- Use vim.schedule to avoid issues with lualine refresh
        vim.schedule(function()
          require("lualine").refresh()
        end)
      end,
    })

    -- Also refresh on LSP attach/detach
    vim.api.nvim_create_autocmd("LspAttach", {
      group = "lualine_augroup",
      callback = function()
        vim.schedule(function()
          require("lualine").refresh()
        end)
      end,
    })

    vim.api.nvim_create_autocmd("LspDetach", {
      group = "lualine_augroup",
      callback = function()
        _G.lsp_progress_message = nil
        vim.schedule(function()
          require("lualine").refresh()
        end)
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
