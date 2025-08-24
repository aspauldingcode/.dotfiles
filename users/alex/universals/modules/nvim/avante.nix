{pkgs, ...}: {
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
            rounded = false;
            align = "center";
          };
          border = "single";
          winblend = 0;
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
      key = "<leader>ad";
      action = "<cmd>AvanteDiff<CR>";
      options = {
        desc = "Show Avante diff";
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
  ];
}
