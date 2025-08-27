{ pkgs, ... }:
{
  programs.nixvim.plugins = {
    # AI cursor assistance with Avante.nvim
    avante = {
      enable = true;
      package = pkgs.unstable.vimPlugins.avante-nvim;

      settings = {
        provider = "openai";
        auto_suggestions = false;

        providers = {
          openai = {
            endpoint = "https://api.openai.com/v1";
            model = "gpt-4o";
            timeout = 30000;
            context_window = 128000;
            extra_request_body = {
              temperature = 0.75;
              max_completion_tokens = 16384;
              reasoning_effort = "medium";
            };
          };
        };

        diff = {
          autojump = true;
          debug = false;
          list_opener = "copen";
        };

        highlights = {
          diff = {
            current = "DiffText";
            incoming = "DiffAdd";
          };
          signs = {
            AvanteInputPromptSign = "Question";
          };
        };

        hints = {
          enabled = true;
        };

        mappings = {
          diff = {
            ours = "co";
            theirs = "ct";
            all_theirs = "ca";
            both = "cb";
            cursor = "cc";
            next = "]x";
            prev = "[x";
          };
          suggestion = {
            accept = "<M-l>";
            next = "<M-]>";
            prev = "<M-[>";
            dismiss = "<C-]>";
          };
          jump = {
            next = "]]";
            prev = "[[";
          };
          submit = {
            normal = "<CR>";
            insert = "<C-s>";
          };
          cancel = {
            normal = "<C-c>";
            insert = "<C-c>";
          };
        };

        windows = {
          width = 30;
          wrap = true;
          sidebar_header = {
            rounded = true;
            align = "center";
          };
          border = "rounded";
          winblend = 10;
          input = {
            prefix = "󰧑 "; # AI icon prefix
            height = 8; # Taller input window
          };
          edit = {
            border = "rounded";
            start_insert = true;
          };
        };

        behaviour = {
          auto_suggestions = false;
          auto_set_highlight_group = true;
          auto_set_keymaps = true;
          auto_apply_diff_after_generation = false;
          support_paste_from_clipboard = true;
        };
      };
    };
  };

  # Add keymaps for Avante.nvim
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>aa";
      action = "<cmd>AvanteAsk<CR>";
      options = {
        desc = "Ask Avante a question";
      };
    }
    {
      mode = "n";
      key = "<leader>ac";
      action = "<cmd>AvanteChat<CR>";
      options = {
        desc = "Open Avante chat";
      };
    }
    {
      mode = "n";
      key = "<leader>at";
      action = "<cmd>AvanteToggle<CR>";
      options = {
        desc = "Toggle Avante chat window";
      };
    }
    {
      mode = "n";
      key = "<leader>ad";
      action = "<cmd>AvanteDiff<CR>";
      options = {
        desc = "Show Avante diff";
      };
    }
    {
      mode = "n";
      key = "<leader>ar";
      action = "<cmd>AvanteRefresh<CR>";
      options = {
        desc = "Refresh Avante";
      };
    }
    {
      mode = "n";
      key = "<leader>af";
      action = "<cmd>AvanteFocus<CR>";
      options = {
        desc = "Focus Avante input";
      };
    }
    {
      mode = "n";
      key = "<leader>as";
      action = "<cmd>AvanteStatus<CR>";
      options = {
        desc = "Show Avante status";
      };
    }
    # Visual mode keymaps for selected text
    {
      mode = "v";
      key = "<leader>aa";
      action = "<cmd>AvanteAsk<CR>";
      options = {
        desc = "Ask Avante about selection";
      };
    }
    {
      mode = "v";
      key = "<leader>ac";
      action = "<cmd>AvanteChat<CR>";
      options = {
        desc = "Chat with Avante about selection";
      };
    }
    {
      mode = "v";
      key = "<leader>ae";
      action = "<cmd>AvanteEdit<CR>";
      options = {
        desc = "Edit selection with Avante";
      };
    }
  ];

  # Add custom Lua configuration for enhanced Avante experience
  programs.nixvim.extraConfigLua = ''
    -- Enhanced Avante configuration and utilities

    -- Custom function to toggle Avante chat with better state management
    local function smart_avante_toggle()
      -- Check if Avante is already open
      local avante_wins = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:match("Avante") or buf_name:match("avante") then
          table.insert(avante_wins, win)
        end
      end

      if #avante_wins > 0 then
        -- Close all Avante windows
        for _, win in ipairs(avante_wins) do
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, false)
          end
        end
        print("󰧑 Avante chat closed")
      else
        -- Open Avante chat
        vim.cmd("AvanteChat")
        print("󰧑 Avante chat opened")
      end
    end

    -- Create user command for the smart toggle
    vim.api.nvim_create_user_command('AvanteToggle', smart_avante_toggle, {
      desc = 'Toggle Avante chat window intelligently'
    })

    -- Auto-commands for better Avante experience
    vim.api.nvim_create_augroup("AvanteEnhancements", { clear = true })

    -- Auto-focus input when opening Avante
    vim.api.nvim_create_autocmd("BufEnter", {
      group = "AvanteEnhancements",
      pattern = "*avante*",
      callback = function()
        if vim.bo.buftype == "prompt" then
          vim.cmd("startinsert")
        end
      end,
      desc = "Auto-focus Avante input"
    })

    -- Improve Avante window appearance
    vim.api.nvim_create_autocmd("FileType", {
      group = "AvanteEnhancements",
      pattern = "avante*",
      callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.showbreak = "↳ "
        vim.opt_local.breakindent = true
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.cursorline = false
      end,
      desc = "Enhance Avante buffer appearance"
    })

    -- Quick commands for common AI tasks
    vim.api.nvim_create_user_command('AvanteExplain', function()
      vim.cmd("AvanteAsk explain this code in detail")
    end, {
      desc = 'Ask Avante to explain the current code'
    })

    vim.api.nvim_create_user_command('AvanteOptimize', function()
      vim.cmd("AvanteAsk optimize this code for performance and readability")
    end, {
      desc = 'Ask Avante to optimize the current code'
    })

    vim.api.nvim_create_user_command('AvanteDebug', function()
      vim.cmd("AvanteAsk help me debug this code and find potential issues")
    end, {
      desc = 'Ask Avante to help debug the current code'
    })

    vim.api.nvim_create_user_command('AvanteTest', function()
      vim.cmd("AvanteAsk write comprehensive tests for this code")
    end, {
      desc = 'Ask Avante to write tests for the current code'
    })

    vim.api.nvim_create_user_command('AvanteDoc', function()
      vim.cmd("AvanteAsk add proper documentation and comments to this code")
    end, {
      desc = 'Ask Avante to document the current code'
    })
  '';
}
