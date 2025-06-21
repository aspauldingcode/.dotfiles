{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # AI Completion plugins
    # copilot-vim = {
    #   enable = true;
    #   settings = {
    #     no_tab_map = true;
    #     assume_mapped = true;
    #     tab_fallback = "";
    #     filetypes = {
    #       "*" = false;
    #       python = true;
    #       javascript = true;
    #       typescript = true;
    #       javascriptreact = true;
    #       typescriptreact = true;
    #       lua = true;
    #       rust = true;
    #       go = true;
    #       java = true;
    #       c = true;
    #       cpp = true;
    #       nix = true;
    #       yaml = true;
    #       json = true;
    #       html = true;
    #       css = true;
    #       scss = true;
    #       markdown = true;
    #       vim = true;
    #       sh = true;
    #     };
    #   };
    # };

    copilot-lua = {
      enable = true;
      settings = {
        suggestion = {
          enabled = false;
        };
        panel = {
          enabled = false;
        };
        server_opts_overrides = {
          settings = {
            advanced = {
              listCount = 10;
              inlineSuggestCount = 3;
            };
          };
        };
      };
    };
    copilot-cmp = {
      enable = true;
      settings = {
        event = [
          "InsertEnter"
          "LspAttach"
        ];
        fix_pairs = true;
      };
    };

    # AI Chat functionality - temporarily disabled to isolate build issue
    # copilot-chat = {
    #   enable = true;
    #   settings = {
    #     question_header = "## User ";
    #     answer_header = "## Copilot ";
    #     error_header = "## Error ";
    #     separator = "───";
    #     show_folds = true;
    #     show_help = true;
    #     auto_follow_cursor = true;
    #     auto_insert_mode = false;
    #     clear_chat_on_new_prompt = false;
    #     context = "buffer";
    #     history_path = {
    #       __raw = "vim.fn.stdpath('data') .. '/copilotchat_history'";
    #     };
    #     callback = null;
    #     selection = {
    #       __raw = "require('CopilotChat.select').buffer";
    #     };
    #     prompts = {
    #       Explain = {
    #         prompt = "/COPILOT_EXPLAIN Write an explanation for the active selection as paragraphs of text.";
    #       };
    #       Review = {
    #         prompt = "/COPILOT_REVIEW Review the selected code.";
    #         callback = {
    #           __raw = "function(response, source) end";
    #         };
    #       };
    #       Fix = {
    #         prompt = "/COPILOT_GENERATE There is a problem in this code. Rewrite the code to show it with the bug fixed.";
    #       };
    #       Optimize = {
    #         prompt = "/COPILOT_GENERATE Optimize the selected code to improve performance and readability.";
    #       };
    #       Docs = {
    #         prompt = "/COPILOT_GENERATE Please add documentation comment for the selection.";
    #       };
    #       Tests = {
    #         prompt = "/COPILOT_GENERATE Please generate tests for my code.";
    #       };
    #       FixDiagnostic = {
    #         prompt = "Please assist with the following diagnostic issue in file:";
    #         selection = {
    #           __raw = "require('CopilotChat.select').diagnostics";
    #         };
    #       };
    #       Commit = {
    #         prompt = "Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit.";
    #         selection = {
    #           __raw = "function(source) return require('CopilotChat.select').gitdiff(source, true) end";
    #         };
    #       };
    #     };
    #   };
    # };

    # # copilot-lua.enable = true; # Disabled to avoid conflict with copilot-vim
    # # copilot-cmp.enable = true; # Temporarily disabled - might auto-enable copilot-lua

    # # Alternative AI completion (uncomment if you prefer Codeium over Copilot)
    # # codeium-nvim = {
    # #   enable = true;
    # #   settings = {
    # #     enable_chat = true;
    # #   };
    # # };

    # Essential completion sources only
    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;

    # Auto-pairs plugin for bracket completion
    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true;
        ts_config = {
          lua = [
            "string"
            "source"
          ];
          javascript = [
            "string"
            "template_string"
          ];
          java = false;
        };
        disable_filetype = [
          "TelescopePrompt"
          "spectre_panel"
        ];
        disable_in_macro = false;
        disable_in_visualblock = false;
        disable_in_replace_mode = true;
        ignored_next_char = {
          __raw = "string.gsub([[ [%w%.] ]], ' ', '')";
        };
        enable_moveright = true;
        enable_afterquote = true;
        enable_check_bracket_line = true;
        enable_bracket_in_quote = true;
        enable_abbr = false;
        break_undo = true;
        check_comma = true;
        map_cr = true;
        map_bs = true;
        map_c_h = false;
        map_c_w = false;
      };
    };

    # Main completion engine
    cmp = {
      enable = true;
      autoEnableSources = true;

      settings = {
        sources = [
          { name = "copilot"; }
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "buffer"; }
          { name = "path"; }
        ];

        mapping = {
          "<C-n>" = {
            __raw = "cmp.mapping.select_next_item()";
          };
          "<C-p>" = {
            __raw = "cmp.mapping.select_prev_item()";
          };
          "<C-Space>" = {
            __raw = "cmp.mapping.complete()";
          };
          "<C-e>" = {
            __raw = "cmp.mapping.abort()";
          };
          "<Esc>" = {
            __raw = "cmp.mapping.abort()";
          };
          "<CR>" = {
            __raw = "cmp.mapping.confirm({ select = true })";
          };
          "<Tab>" = {
            __raw = ''
              cmp.mapping(function(fallback)
                local luasnip = require('luasnip')
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expandable() then
                  luasnip.expand()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
          };
          "<S-Tab>" = {
            __raw = ''
              cmp.mapping(function(fallback)
                local luasnip = require('luasnip')
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' })
            '';
          };
        };

        experimental = {
          ghost_text = true;
        };
      };
    };

    # Snippet engine
    luasnip = {
      enable = true;
      fromVscode = [
        {
          lazyLoad = true;
          paths = "${pkgs.vimPlugins.friendly-snippets}";
        }
      ];
    };

    # LSP kind icons for completion
    lspkind = {
      enable = true;
      symbolMap = {
        Copilot = "";
      };
    };
  };

  # Configure autopairs integration with cmp
  programs.nixvim.extraConfigLua = ''
    -- Set up cmp integration with autopairs
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local cmp = require('cmp')
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  '';

  # Keymaps for AI completion
  programs.nixvim.keymaps = [
    # Snippet navigation
    {
      mode = [
        "i"
        "s"
      ];
      key = "<C-k>";
      action = "<cmd>lua require('luasnip').expand_or_jump()<CR>";
      options.desc = "Expand or jump to next snippet placeholder";
    }
    {
      mode = [
        "i"
        "s"
      ];
      key = "<C-j>";
      action = "<cmd>lua require('luasnip').jump(-1)<CR>";
      options.desc = "Jump to previous snippet placeholder";
    }
  ];
}
