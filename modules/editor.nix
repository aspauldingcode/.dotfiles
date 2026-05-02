{
  flake.modules.homeManager.editor = { pkgs, inputs, lib, config, ... }:
  let
    isDarwin = pkgs.stdenv.isDarwin;
  in
  {
    imports = [ inputs.nixvim.homeModules.nixvim ];

    sops.secrets.anthropic_api_key = {};

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      enableMan = false; # Disable man pages to fix the 'options.json' context warning

      # ── Global Options ──────────────────────────────────────────
      globals.mapleader = " ";
      globals.maplocalleader = ",";

      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        smartindent = true;
        wrap = false;
        cursorline = true;
        scrolloff = 8;
        signcolumn = "yes";
        termguicolors = true;
        mouse = "a";
        undofile = true;
        ignorecase = true;
        smartcase = true;
        splitbelow = true;
        splitright = true;
        updatetime = 250;
        timeoutlen = 300;
        clipboard = "unnamedplus";
        completeopt = "menu,menuone,noselect";
        colorcolumn = "80";

        # Use swap files but handle them automatically via vim-autoswap
        swapfile = true;
        backup = false;
        writebackup = false;
        shortmess = "filnxtToOFc"; # Removed 'A' to let vim-autoswap detect the prompt
      };

      # ── Colorscheme: applied via mini.base16 (Stylix nixvim target disabled) ──

      # ── Treesitter ──────────────────────────────────────────────
      plugins.treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensure_installed = [
            "bash" "c" "cpp" "css" "html" "java" "javascript"
            "json" "lua" "markdown" "markdown_inline" "nix"
            "python" "rust" "swift" "toml" "typescript" "tsx"
            "vim" "vimdoc" "yaml" "objc"
          ];
        };
      };

      # ── LSP ─────────────────────────────────────────────────────
      plugins.lsp = {
        enable = true;
        inlayHints = false; # Disabled globally to prevent SourceKit-LSP crashes
        servers = {
          # Nix
          nil_ls.enable = true;
          # Python
          pyright.enable = true;
          # TypeScript / JavaScript
          ts_ls.enable = true;
          # C / C++ / Objective-C
          clangd.enable = true;
          # Rust (handled by rustaceanvim, do NOT enable rust_analyzer here)
          # Java
          jdtls.enable = true;
          # Lua
          lua_ls.enable = true;
          # HTML / CSS / JSON
          html.enable = true;
          cssls.enable = true;
          jsonls.enable = true;
          # YAML
          yamlls.enable = true;
          # Bash
          bashls.enable = true;
          # Assembly (ARMv7 support)
          asm_lsp.enable = true;
          # Swift
          sourcekit = {
            enable = true;
            # Aggressively disable inlay hints to prevent the -32001 crash
            onAttach.function = ''
              client.server_capabilities.inlayHintProvider = false
            '';
          };
        };
      };

      # ── Rust (rustaceanvim handles rust-analyzer + DAP) ─────────
      plugins.rustaceanvim = {
        enable = true;
        settings.server.default_settings = {
          "rust-analyzer" = {
            check.command = "clippy";
            inlayHints = {
              closingBraceHints.enable = true;
              parameterHints.enable = true;
              typeHints.enable = true;
            };
          };
        };
      };

      # ── Completion (blink.cmp — modern, Rust-powered) ───────────
      plugins.blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "default";
          sources = {
            default = [ "lsp" "path" "snippets" "buffer" ];
          };
          signature.enabled = true;
          completion = {
            documentation.auto_show = true;
            ghost_text.enabled = false; # Let copilot-lua handle ghost text
          };
        };
      };

      # Industry-standard code snippets
      plugins.friendly-snippets.enable = true;
      plugins.luasnip.enable = true;

      # LLM Autocomplete (Inline)
      plugins.copilot-lua = {
        enable = true;
        settings = {
          suggestion = {
            enabled = true;
            auto_trigger = true;
            keymap = {
              accept = "<M-l>";
              accept_word = false;
              accept_line = false;
              next = "<M-]>";
              prev = "<M-[>";
              dismiss = "<C-]>";
            };
          };
          panel.enabled = false;
        };
      };

      # ── Formatting (conform.nvim) ──────────────────────────────
      plugins.conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = "fallback";
            timeout_ms = 2000;
          };
          formatters_by_ft = {
            python = [ "ruff_format" "isort" ];
            javascript = [[ "prettierd" "prettier" ]];
            typescript = [[ "prettierd" "prettier" ]];
            javascriptreact = [[ "prettierd" "prettier" ]];
            typescriptreact = [[ "prettierd" "prettier" ]];
            html = [[ "prettierd" "prettier" ]];
            css = [[ "prettierd" "prettier" ]];
            json = [[ "prettierd" "prettier" ]];
            yaml = [[ "prettierd" "prettier" ]];
            markdown = [[ "prettierd" "prettier" ]];
            nix = [ "nixfmt" ];
            rust = [ "rustfmt" ];
            c = [ "clang-format" ];
            cpp = [ "clang-format" ];
            objc = [ "clang-format" ];
            java = [ "clang-format" ];
            swift = [ "swiftformat" ];
            lua = [ "stylua" ];
            sh = [ "shfmt" ];
            bash = [ "shfmt" ];
            zsh = [ "shfmt" ];
            asm = [ "asmfmt" ];
            "_" = [ "trim_whitespace" ];
          };
        };
      };

      # ── Linting (nvim-lint) ─────────────────────────────────────
      plugins.lint = {
        enable = true;
        lintersByFt = {
          python = [ "ruff" ];
          javascript = [ "eslint_d" ];
          typescript = [ "eslint_d" ];
          nix = [ "statix" "deadnix" ];
          sh = [ "shellcheck" ];
          bash = [ "shellcheck" ];
          zsh = [ "shellcheck" ];
          swift = [ "swiftlint" ];
        };
      };

      # ── Autocommands ──────────────────────────────────────────
      autoCmd = [
        # Linting
        {
          event = [ "BufWritePost" "InsertLeave" ];
          callback.__raw = ''
            function()
              require('lint').try_lint()
            end
          '';
        }
        # Auto-open Neo-tree on directory
        {
          event = [ "VimEnter" ];
          callback.__raw = ''
            function()
              if vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
                require("neo-tree.command").execute({ action = "show" })
              end
            end
          '';
        }
      ];

      # ── Debugging (DAP) ─────────────────────────────────────────
      plugins.dap-ui.enable = true;
      plugins.dap-virtual-text.enable = true;
      plugins.dap = {
        enable = true;
        adapters = {
          executables = {
            python = {
              command = "${pkgs.python3Packages.debugpy}/bin/debugpy-adapter";
            };
          } // (if isDarwin then {
            lldb = {
              command = "lldb-dap"; # From Xcode Command Line Tools
            };
          } else {
            gdb = {
              command = "${pkgs.gdb}/bin/gdb";
              args = [ "--interpreter=dap" ];
            };
          });
        };
        configurations = {
          python = [
            {
              name = "Launch file";
              type = "python";
              request = "launch";
              program.__raw = ''
                function()
                  return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                end
              '';
            }
          ];
          c = [
            {
              name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
              type = if isDarwin then "lldb" else "gdb";
              request = "launch";
              program.__raw = ''
                function()
                  return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                end
              '';
              cwd = "\${workspaceFolder}";
            }
          ];
          cpp = [
            {
              name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
              type = if isDarwin then "lldb" else "gdb";
              request = "launch";
              program.__raw = ''
                function()
                  return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                end
              '';
              cwd = "\${workspaceFolder}";
            }
          ];
          rust = [
            {
              name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
              type = if isDarwin then "lldb" else "gdb";
              request = "launch";
              program.__raw = ''
                function()
                  return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                end
              '';
              cwd = "\${workspaceFolder}";
            }
          ];
        };
      };

      # ── Telescope ───────────────────────────────────────────────
      plugins.telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
        settings.defaults = {
          layout_strategy = "horizontal";
          sorting_strategy = "ascending";
          layout_config.prompt_position = "top";
        };
      };

      # ── File Browser (neo-tree) ─────────────────────────────────
      plugins.neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          filesystem = {
            use_libuv_file_watcher = true;
            follow_current_file.enabled = true;
            hijack_netrw_behavior = "open_current";
            filtered_items.visible = true;
          };
          window.position = "left";
          window.width = 35;
        };
      };

      # ── Dashboard (alpha-nvim greeter) ──────────────────────────
      plugins.alpha = {
        enable = true;
        theme = "dashboard";
        # The dashboard theme is dynamic and handles centering automatically
        # for any buffer frame size.
        settings = {
          header.val = [
            " ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗ "
            " ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║ "
            " ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║ "
            " ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║ "
            " ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║ "
            " ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ "
            "                                              "
            "           󰚝  LLM-POWERED CODING ACTIVE       "
          ];
          config.opts.noautocmd = true;
          footer.val = [ "Dendritic System Framework" ];
        };
      };

      # ── Yazi (terminal file manager integration) ───────────────
      plugins.yazi = {
        enable = true;
        settings = {
          open_for_directories = false; # Let Neo-tree handle directories for now
        };
      };

      # ── Oil (inline file editing) ───────────────────────────────
      plugins.oil = {
        enable = true;
        settings = {
          default_file_explorer = false;
          delete_to_trash = true;
          view_options.show_hidden = true;
        };
      };

      # ── Git ─────────────────────────────────────────────────────
      plugins.gitsigns.enable = true;
      plugins.fugitive.enable = true;
      plugins.diffview.enable = true;

      # ── UI & Quality of Life ────────────────────────────────────
      plugins.lualine.enable = true;
      plugins.which-key.enable = true;
      plugins.nvim-autopairs.enable = true;
      plugins.indent-blankline.enable = true;
      plugins.todo-comments.enable = true;
      plugins.trouble.enable = true;
      plugins.noice.enable = true;
      plugins.notify.enable = true;
      plugins.web-devicons.enable = true;
      plugins.comment.enable = true;
      plugins.illuminate.enable = true;
      plugins.toggleterm.enable = true;
      plugins.mini = {
        enable = true;
        modules = {
          # base16 is setup manually in extraConfigLua
          surround = {};
          bufremove = {};
        };
      };
      
      # ── Better Markdown & Codeblocks (matches VSCode/Cursor) ─────
      plugins.render-markdown = {
        enable = true;
        settings = {
          code = {
            sign = false;
            width = "block";
            right_pad = 4;
            background.hl = "MarkdownCode";
          };
          heading = {
            sign = false;
            icons = [ "󰲡 " "󰲣 " "󰲥 " "󰲧 " "󰲩 " "󰲫 " ];
          };
        };
      };

      # ── Agentic AI Coding (CodeCompanion) ───────────────────────
      extraPlugins = with pkgs.vimPlugins; [
        vim-autoswap # Automatically handle .swp file prompts
        (pkgs.vimUtils.buildVimPlugin {
          pname = "codecompanion.nvim";
          version = "latest";
          src = pkgs.fetchFromGitHub {
            owner = "olimorris";
            repo = "codecompanion.nvim";
            rev = "fcfb7130f570ef2bbb52cbe9167c1999bc41029a";
            hash = "sha256-bcFT8PAFicRgPNAoxzrcAYH1wYJQ6Yu/E94H7M2DNaA=";
          };
          dependencies = [ plenary-nvim nvim-treesitter ];
          doCheck = false;
        })
      ];

      extraConfigLua = ''
        -- CodeCompanion setup
        local ok, cc = pcall(require, "codecompanion")
        if ok then
          cc.setup({
            adapters = {
              anthropic = function()
                return require("codecompanion.adapters").extend("anthropic", {
                  env = {
                    api_key = "cmd:cat ${config.sops.secrets.anthropic_api_key.path}",
                  },
                })
              end,
            },
            strategies = {
              chat = { adapter = "anthropic" },
              inline = { adapter = "anthropic" },
              agent = { adapter = "anthropic" },
            },
          })
        end

        -- Apply Stylix theme via mini.base16
        local ok2, base16 = pcall(require, "mini.base16")
        if ok2 then
          base16.setup({
            palette = {
              base00 = "${config.lib.stylix.colors.withHashtag.base00}",
              base01 = "${config.lib.stylix.colors.withHashtag.base01}",
              base02 = "${config.lib.stylix.colors.withHashtag.base02}",
              base03 = "${config.lib.stylix.colors.withHashtag.base03}",
              base04 = "${config.lib.stylix.colors.withHashtag.base04}",
              base05 = "${config.lib.stylix.colors.withHashtag.base05}",
              base06 = "${config.lib.stylix.colors.withHashtag.base06}",
              base07 = "${config.lib.stylix.colors.withHashtag.base07}",
              base08 = "${config.lib.stylix.colors.withHashtag.base08}",
              base09 = "${config.lib.stylix.colors.withHashtag.base09}",
              base0A = "${config.lib.stylix.colors.withHashtag.base0A}",
              base0B = "${config.lib.stylix.colors.withHashtag.base0B}",
              base0C = "${config.lib.stylix.colors.withHashtag.base0C}",
              base0D = "${config.lib.stylix.colors.withHashtag.base0D}",
              base0E = "${config.lib.stylix.colors.withHashtag.base0E}",
              base0F = "${config.lib.stylix.colors.withHashtag.base0F}",
            },
          })
        end

        -- ── VS Code / Cursor 1:1 Aesthetic Refinements ────────────────
        
        -- Enable Cursive Italics for logic flow (matches premium themes)
        vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = "${config.lib.stylix.colors.withHashtag.base03}" })
        vim.api.nvim_set_hl(0, "Keyword", { italic = true })
        vim.api.nvim_set_hl(0, "Conditional", { italic = true })
        vim.api.nvim_set_hl(0, "Repeat", { italic = true })
        vim.api.nvim_set_hl(0, "Function", { italic = true, bold = true })
        vim.api.nvim_set_hl(0, "Operator", { fg = "${config.lib.stylix.colors.withHashtag.base05}" }) -- Muted operators
        
        -- High-Fidelity Treesitter / LSP Semantic Token Overrides
        -- This makes the syntax tree "pop" like VS Code's TextMate scopes
        vim.api.nvim_set_hl(0, "@variable", { fg = "${config.lib.stylix.colors.withHashtag.base05}" })
        vim.api.nvim_set_hl(0, "@variable.member", { fg = "${config.lib.stylix.colors.withHashtag.base08}" }) -- Fields/Members
        vim.api.nvim_set_hl(0, "@property", { fg = "${config.lib.stylix.colors.withHashtag.base08}" })
        vim.api.nvim_set_hl(0, "@parameter", { fg = "${config.lib.stylix.colors.withHashtag.base09}", italic = true }) -- Parameters in italics
        vim.api.nvim_set_hl(0, "@constructor", { fg = "${config.lib.stylix.colors.withHashtag.base0D}", bold = true })
        
        -- Nix Specific Highlighting Refinements
        vim.api.nvim_set_hl(0, "@variable.nix", { fg = "${config.lib.stylix.colors.withHashtag.base05}" })
        vim.api.nvim_set_hl(0, "@function.call.nix", { fg = "${config.lib.stylix.colors.withHashtag.base0D}" })
        
        -- Clean up UI elements to match VS Code's "Flat" look
        vim.api.nvim_set_hl(0, "LineNr", { fg = "${config.lib.stylix.colors.withHashtag.base02}" })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "${config.lib.stylix.colors.withHashtag.base04}", bold = true })
        vim.api.nvim_set_hl(0, "VertSplit", { fg = "${config.lib.stylix.colors.withHashtag.base01}", bg = "NONE" })
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "${config.lib.stylix.colors.withHashtag.base01}", bg = "NONE" })

        -- Fancy DAP Breakpoint Icons
        vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "DiagnosticWarn" })

        -- Match VSCode CodeBlock backgrounds
        vim.api.nvim_set_hl(0, "MarkdownCode", { bg = "${config.lib.stylix.colors.withHashtag.base01}" })
        vim.api.nvim_set_hl(0, "MarkdownCodeBlock", { bg = "${config.lib.stylix.colors.withHashtag.base01}" })

        -- ── Modern Textutil Integration (RTF/DOC Editing) ─────────────
        -- Transparently edit RTF, DOC, and WordML files as plain text
        local rtf_group = vim.api.nvim_create_augroup("Textutil", { clear = true })

        vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
          group = rtf_group,
          pattern = { "*.rtf", "*.doc", "*.docx", "*.wordml" },
          callback = function(ev)
            local file = ev.file
            local cmd = string.format("textutil -convert txt -stdout %q", file)
            local output = vim.fn.systemlist(cmd)
            vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
            vim.api.nvim_set_option_value("modified", false, { buf = 0 })
            vim.api.nvim_set_option_value("filetype", "text", { buf = 0 })
          end,
        })

        vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
          group = rtf_group,
          pattern = { "*.rtf", "*.doc", "*.docx", "*.wordml" },
          callback = function(ev)
            local file = ev.file
            local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
            local format = file:match("%.(%w+)$")
            -- Map extensions to textutil formats
            if format == "docx" or format == "doc" then format = "wordml" end
            
            local cmd = string.format("textutil -convert %s -stdin -output %q", format, file)
            vim.fn.system(cmd, content)
            vim.api.nvim_set_option_value("modified", false, { buf = 0 })
            vim.notify("Saved as " .. format, vim.log.levels.INFO)
          end,
        })
      '';

      # ── Keymaps ─────────────────────────────────────────────────
      keymaps = [
        # File browser
        { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Toggle Neo-tree"; }
        { mode = "n"; key = "-"; action = "<cmd>Oil<cr>"; options.desc = "Open Oil"; }

        # Telescope
        { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find Files"; }
        { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live Grep"; }
        { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; options.desc = "Buffers"; }
        { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<cr>"; options.desc = "Help Tags"; }
        { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope oldfiles<cr>"; options.desc = "Recent Files"; }
        { mode = "n"; key = "<leader>fd"; action = "<cmd>Telescope diagnostics<cr>"; options.desc = "Diagnostics"; }
        { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<cr>"; options.desc = "Document Symbols"; }

        # LSP
        { mode = "n"; key = "gd"; action = "<cmd>Telescope lsp_definitions<cr>"; options.desc = "Go to Definition"; }
        { mode = "n"; key = "gr"; action = "<cmd>Telescope lsp_references<cr>"; options.desc = "References"; }
        { mode = "n"; key = "gi"; action = "<cmd>Telescope lsp_implementations<cr>"; options.desc = "Implementations"; }
        { mode = "n"; key = "K"; action.__raw = "vim.lsp.buf.hover"; options.desc = "Hover"; }
        { mode = "n"; key = "<leader>ca"; action.__raw = "vim.lsp.buf.code_action"; options.desc = "Code Action"; }
        { mode = "n"; key = "<leader>cr"; action.__raw = "vim.lsp.buf.rename"; options.desc = "Rename Symbol"; }

        # Diagnostics
        { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; options.desc = "Diagnostics (Trouble)"; }
        { mode = "n"; key = "[d"; action.__raw = "vim.diagnostic.goto_prev"; options.desc = "Prev Diagnostic"; }
        { mode = "n"; key = "]d"; action.__raw = "vim.diagnostic.goto_next"; options.desc = "Next Diagnostic"; }

        # DAP (Debug)
        { mode = "n"; key = "<leader>db"; action.__raw = "require('dap').toggle_breakpoint"; options.desc = "Toggle Breakpoint"; }
        { mode = "n"; key = "<leader>dc"; action.__raw = "require('dap').continue"; options.desc = "Continue"; }
        { mode = "n"; key = "<leader>di"; action.__raw = "require('dap').step_into"; options.desc = "Step Into"; }
        { mode = "n"; key = "<leader>do"; action.__raw = "require('dap').step_over"; options.desc = "Step Over"; }
        { mode = "n"; key = "<leader>dO"; action.__raw = "require('dap').step_out"; options.desc = "Step Out"; }
        { mode = "n"; key = "<leader>du"; action.__raw = "require('dapui').toggle"; options.desc = "Toggle DAP UI"; }
        { mode = "n"; key = "<leader>dr"; action.__raw = "require('dap').repl.open"; options.desc = "Open REPL"; }

        # Git
        { mode = "n"; key = "<leader>gg"; action = "<cmd>Git<cr>"; options.desc = "Git Status (Fugitive)"; }
        { mode = "n"; key = "<leader>gd"; action = "<cmd>DiffviewOpen<cr>"; options.desc = "Diff View"; }

        # Terminal
        { mode = "n"; key = "<leader>t"; action = "<cmd>ToggleTerm<cr>"; options.desc = "Toggle Terminal"; }

        # AI / Agentic
        { mode = "n"; key = "<leader>ac"; action = "<cmd>CodeCompanionChat<cr>"; options.desc = "AI Chat"; }
        { mode = "v"; key = "<leader>ac"; action = "<cmd>CodeCompanionChat<cr>"; options.desc = "AI Chat (selection)"; }
        { mode = "n"; key = "<leader>ai"; action = "<cmd>CodeCompanion<cr>"; options.desc = "AI Inline"; }

        # Yazi
        { mode = "n"; key = "<leader>y"; action = "<cmd>Yazi<cr>"; options.desc = "Open Yazi"; }

        # Buffers
        { mode = "n"; key = "<leader>bd"; action.__raw = "require('mini.bufremove').delete"; options.desc = "Delete Buffer"; }
        { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Prev Buffer"; }
        { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next Buffer"; }

        # Window navigation
        { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move Left"; }
        { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move Down"; }
        { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move Up"; }
        { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move Right"; }

        # Format
        { mode = "n"; key = "<leader>cf"; action = "<cmd>lua require('conform').format()<cr>"; options.desc = "Format File"; }
        # MicroVM
        {
          mode = "n";
          key = "<leader>vm";
          action = "<cmd>TermExec cmd='microvm-run'<cr>";
          options.desc = "Launch MicroVM";
        }
      ];
    };

    # ── Formatter & Linter packages ─────────────────────────────
    home.packages = with pkgs; [
      # Formatters
      nixfmt              # Nix (Official)
      prettierd           # JS/TS/HTML/CSS/JSON/YAML/MD
      stylua              # Lua
      shfmt               # Shell
      ruff                # Python (formatter + linter)
      # Linters
      statix              # Nix
      shellcheck          # Shell
      eslint_d            # JS/TS
      asmfmt              # Assembly formatter
      asm-lsp             # Assembly LSP (ARM support)
      swiftformat         # Swift
      swiftlint           # Swift
      sourcekit-lsp       # Swift LSP
      # VSCode Extensions (available in PATH/store)
      vscode-extensions.bbenoist.nix
      vscode-extensions.jnoortheen.nix-ide
    ] ++ lib.optionals (!isDarwin) [
      gdb                 # Debugger (Linux)
    ];
  };
}
