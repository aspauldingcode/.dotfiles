{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # AI cursor assistance with Avante.nvim
    avante = {
      enable = true;
      autoLoad = true;
      package = pkgs.vimPlugins.avante-nvim;

      settings = {
        provider = "openai";
        auto_suggestions_frequency = "copilot";

        openai = {
          endpoint = "https://api.openai.com/v1";
          model = "gpt-4o";
          timeout = 30000;
          temperature = 0;
          max_tokens = 4096;
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

          hints.enabled = true;

          mappings = {
            diff = {
              next = "]x";
              prev = "[x";
              ours = "co";
              theirs = "ct";
              both = "cb";
              none = "c0";
            };
            jump = {
              next = "]]";
              prev = "[[";
            };
          };

          windows = {
            width = 30;
            wrap = true;
            sidebar_header = {
              rounded = true;
              align = "center";
            };
          };
        };
      };
    };
  };
}
