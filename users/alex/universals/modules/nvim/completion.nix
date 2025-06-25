{ pkgs, ... }:

{
  programs.nixvim.plugins = {
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
          {
            name = "nvim_lsp";
            priority = 1000;
            max_item_count = 20;
          }
          {
            name = "cmp_ai";
            priority = 800;
            max_item_count = 10;
          }
          {
            name = "luasnip";
            priority = 750;
            max_item_count = 5;
          }
          {
            name = "buffer";
            priority = 500;
            keyword_length = 3;
            max_item_count = 5;
          }
          {
            name = "path";
            priority = 300;
            max_item_count = 5;
          }
        ];

        completion = {
          autocomplete = [
            {
              __raw = "require('cmp.types').cmp.TriggerEvent.TextChanged";
            }
          ];
          completeopt = "menu,menuone,noselect";
        };

        mapping = {
          "<C-n>" = {
            __raw = "cmp.mapping.select_next_item()";
          };
          "<C-p>" = {
            __raw = "cmp.mapping.select_prev_item()";
          };
          "<C-j>" = {
            __raw = "cmp.mapping.select_next_item()";
          };
          "<C-k>" = {
            __raw = "cmp.mapping.select_prev_item()";
          };
          "<Down>" = {
            __raw = "cmp.mapping.select_next_item()";
          };
          "<Up>" = {
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
                  cmp.confirm({ select = true })
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
          # Dedicated AI completion trigger
          "<C-x>" = {
            __raw = ''
              cmp.mapping(
                cmp.mapping.complete({
                  config = {
                    sources = cmp.config.sources({
                      { name = 'cmp_ai' },
                    }),
                  },
                }),
                { 'i' }
              )
            '';
          };
        };

        experimental = {
          ghost_text = true;
        };

        window = {
          completion = {
            __raw = "cmp.config.window.bordered()";
          };
          documentation = {
            __raw = "cmp.config.window.bordered()";
          };
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
        # Removed Copilot symbol - LSP-AI integrates through nvim_lsp
        Text = "󰉿";
        Method = "󰆧";
        Function = "󰊕";
        Constructor = "";
        Field = "󰜢";
        Variable = "󰀫";
        Class = "󰠱";
        Interface = "";
        Module = "";
        Property = "󰜢";
        Unit = "󰑭";
        Value = "󰎠";
        Enum = "";
        Keyword = "󰌋";
        Snippet = "";
        Color = "";
        File = "󰈙";
        Reference = "";
        Folder = "󰉋";
        EnumMember = "";
        Constant = "";
        Struct = "󰙅";
        Event = "";
        Operator = "󰆕";
        TypeParameter = "";
        AI = "󰧑"; # AI completion symbol
      };
    };

    # AI completion source for nvim-cmp
    cmp-ai = {
      enable = true;
      settings = {
        max_lines = 1000;
        provider = "OpenAI";
        provider_options = {
          model = "gpt-4";
        };
        notify = true;
        notify_callback = ''
          function(msg)
            vim.notify(msg)
          end
        '';
        run_on_every_keystroke = true;
        ignored_file_types = {
          # default is not to ignore
          # uncomment to ignore in lua:
          # lua = true
        };
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

  # Keymaps for AI completion and snippets
  programs.nixvim.keymaps = [
    # Snippet navigation - using different keys to avoid conflict with completion
    {
      mode = [
        "i"
        "s"
      ];
      key = "<C-l>"; # Changed from <C-k> to avoid conflict
      action = "<cmd>lua require('luasnip').expand_or_jump()<CR>";
      options = {
        desc = "Expand or jump to next snippet placeholder";
      };
    }
    {
      mode = [
        "i"
        "s"
      ];
      key = "<C-h>"; # Changed from <C-j> to avoid conflict
      action = "<cmd>lua require('luasnip').jump(-1)<CR>";
      options = {
        desc = "Jump to previous snippet placeholder";
      };
    }
  ];
}
