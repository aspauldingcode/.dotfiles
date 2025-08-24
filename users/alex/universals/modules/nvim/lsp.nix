{pkgs, ...}: {
  programs.nixvim.plugins = {
    lsp = {
      enable = true;

      # Configure diagnostic display
      onAttach = ''
        -- Set up buffer-local keymaps
        local bufnr = vim.api.nvim_get_current_buf()

        -- LSP navigation
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = 'Go to declaration' })
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = bufnr, desc = 'Go to implementation' })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, desc = 'Find references' })
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover documentation' })
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = bufnr, desc = 'Signature help' })

        -- LSP actions
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Rename symbol' })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code actions' })
        vim.keymap.set('v', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code actions' })

        -- Formatting
        vim.keymap.set('n', '<leader>lf', function()
          vim.lsp.buf.format({ async = true })
        end, { buffer = bufnr, desc = 'Format buffer' })

        -- LSP info
        vim.keymap.set('n', '<leader>ls', function()
          local clients = vim.lsp.get_clients({ bufnr = bufnr })
          if #clients == 0 then
            print('No LSP clients attached')
          else
            local client_names = {}
            for _, client in ipairs(clients) do
              table.insert(client_names, client.name)
            end
            print('LSP clients: ' .. table.concat(client_names, ', '))
          end
        end, { buffer = bufnr, desc = 'LSP status' })

        -- Avante AI chat keymap
        vim.keymap.set('n', '<leader>ac', '<cmd>AvanteChat<cr>', { buffer = bufnr, desc = 'Open Avante AI chat' })

        -- LSP-AI specific keymaps
        vim.keymap.set('n', '<leader>ag', function()
          -- Trigger AI completion via cmp-ai
          local cmp = require('cmp')
          if cmp.visible() then
            cmp.close()
          end
          cmp.complete({
            config = {
              sources = {
                { name = 'cmp_ai' }
              }
            }
          })
        end, { buffer = bufnr, desc = 'Trigger AI completion' })

        vim.keymap.set('n', '<leader>at', function()
          -- Check if cmp-ai is available
          local has_cmp_ai, cmp_ai = pcall(require, 'cmp_ai')
          if has_cmp_ai then
            print('cmp-ai is active and ready')
          else
            print('cmp-ai is not available')
          end
        end, { buffer = bufnr, desc = 'AI completion status' })

        vim.keymap.set('n', '<leader>as', function()
          -- Check API key and cmp-ai status
          local api_key = os.getenv("OPENAI_API_KEY")
          if api_key then
            print('OpenAI API key is set - cmp-ai ready')
          else
            print('OpenAI API key not set - export OPENAI_API_KEY')
          end
        end, { buffer = bufnr, desc = 'AI setup check' })
      '';

      servers = {
        # Python
        pylsp = {
          enable = true;
          settings = {
            pylsp = {
              plugins = {
                # Disable pylsp's built-in formatters - use efmls-configs instead
                black = {
                  enabled = false;
                };
                isort = {
                  enabled = false;
                };
                yapf = {
                  enabled = false;
                };
                autopep8 = {
                  enabled = false;
                };

                # Keep linting and other features
                pycodestyle = {
                  enabled = true;
                };
                pyflakes = {
                  enabled = true;
                };
                pylint = {
                  enabled = false;
                };
                mccabe = {
                  enabled = true;
                };
                rope_completion = {
                  enabled = true;
                };
                jedi_completion = {
                  enabled = true;
                };
                jedi_hover = {
                  enabled = true;
                };
                jedi_references = {
                  enabled = true;
                };
                jedi_signature_help = {
                  enabled = true;
                };
                jedi_symbols = {
                  enabled = true;
                };
              };
            };
          };
        };

        # JavaScript/TypeScript
        ts_ls = {
          enable = true;
        };
        eslint = {
          enable = true;
        };

        # Lua
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT";
              };
              diagnostics = {
                globals = ["vim"];
              };
              workspace = {
                library = ["\${3rd}/luv/library"];
                checkThirdParty = false;
              };
              telemetry = {
                enable = false;
              };
            };
          };
        };

        # Nix
        nixd = {
          enable = true;
          settings = {
            nixpkgs = {
              expr = "import <nixpkgs> { }";
            };
            formatting = {
              command = ["nixpkgs-fmt"];
            };
          };
        };
      };
    };

    # LSP signature help
    lsp-signature = {
      enable = true;
      settings = {
        bind = true;
        floating_window = true;
        floating_window_above_cur_line = true;
        floating_window_off_x = 1;
        floating_window_off_y = 0;
        close_timeout = 4000;
        fix_pos = false;
        hint_enable = true;
        hint_prefix = "🐼 ";
        hi_parameter = "LspSignatureActiveParameter";
        handler_opts = {
          border = "rounded";
        };
        always_trigger = false;
        auto_close_after = null;
        extra_trigger_chars = [
          "("
          ","
        ];
        zindex = 200;
        padding = "";
        shadow_blend = 36;
        shadow_guibg = "Black";
        timer_interval = 200;
        toggle_key = null;
        select_signature_key = null;
        move_cursor_key = null;
      };
    };

    # Formatting via efm
    efmls-configs = {
      enable = true;
      setup = {
        python = {
          formatter = "black";
          linter = "flake8";
        };
        javascript = {
          formatter = "prettier";
        };
        typescript = {
          formatter = "prettier";
        };
        lua = {
          formatter = "stylua";
        };
        nix = {
          formatter = "nixfmt";
          linter = "statix";
        };
      };
    };
  };

  # Configure diagnostic signs
  programs.nixvim.diagnostic = {
    settings = {
      signs = {
        text = {
          error = "";
          warn = "";
          hint = "";
          info = "";
        };
      };
      virtual_text = false; # Disable virtual text since we show info on hover
      float = {
        focusable = false;
        style = "minimal";
        border = "rounded";
        source = "always";
        header = "";
        prefix = "";
      };
      severity_sort = true;
      update_in_insert = false;
    };
  };

  # Enhanced diagnostic sign configuration to ensure icons show properly
  programs.nixvim.extraConfigLua = ''
    -- Configure diagnostic signs with proper icons
    local signs = {
      Error = "",  -- nf-fa-times_circle
      Warn = "",   -- nf-fa-exclamation_triangle
      Hint = "",   -- nf-fa-question_circle
      Info = "",   -- nf-fa-info_circle
    }

    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Also ensure the diagnostic configuration uses the right signs
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "",
          [vim.diagnostic.severity.WARN] = "",
          [vim.diagnostic.severity.HINT] = "",
          [vim.diagnostic.severity.INFO] = "",
        }
      },
      virtual_text = false,
      update_in_insert = false,
      underline = true,
      severity_sort = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
  '';
}
