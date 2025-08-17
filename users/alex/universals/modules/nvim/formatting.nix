{ pkgs, ... }:
{
  programs.nixvim.plugins = {
    # Enable lsp-format for none-ls integration
    lsp-format.enable = true;

    preview = {
      enable = true;
      autoLoad = true;
    };

    none-ls = {
      enable = true;
      enableLspFormat = true;
      autoLoad = true;
      sources = {
        formatting = {
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
        };
        diagnostics.checkstyle = {
          enable = true;
          settings = {
            extra_args = [
              "-c"
              "${./plugin/checkstyle/google_checks.xml}"
            ];
            diagnostics_format = "[#{c}] #{m} (#{s})";
          };
        };
      };
      settings = {
        notify_format = "[null-ls] %s";
        diagnostics_format = "[#{c}] #{m} (#{s})";
        temp_dir = "/tmp";
        update_in_insert = false;
      };
    };

    # efmls-configs configuration moved to lsp.nix to avoid conflicts

    # Enable format on save
    # programs.nixvim.autoCmd = [
    #   {
    #     event = [ "BufWritePre" ];
    #     pattern = "*";
    #     callback = {
    #       __raw = ''
    #         function()
    #           -- Skip if we're in insert mode (user is still typing)
    #           if vim.api.nvim_get_mode().mode == 'i' then
    #             return
    #           end

    #           -- Only format if LSP is attached and supports formatting
    #           local clients = vim.lsp.get_clients({ bufnr = 0 })
    #           for _, client in ipairs(clients) do
    #             if client.supports_method("textDocument/formatting") then
    #               vim.lsp.buf.format({
    #                 async = false,
    #                 timeout_ms = 2000,
    #               })
    #               break
    #             end
    #           end
    #         end
    #       '';
    #     };
    #   }
    # ];

    # Add keymaps for manual formatting
    # NOTE: LSP formatting keymaps are now defined in lsp.nix using lsp.keymaps
    # This ensures they only activate when an LSP server is actually attached
    # programs.nixvim.keymaps = [];
  };
}
