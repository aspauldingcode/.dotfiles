{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    lsp = {
      enable = true;

      # Configure diagnostic display
      onAttach = ''
        -- Comprehensive LSP sync error prevention for Neovim 0.11.2
        -- This addresses multiple known sync issues including nil prev_line, line_ending, and other race conditions
        local function setup_lsp_sync_protection()
          -- Protect the main LSP module functions
          local lsp_ok, lsp = pcall(require, 'vim.lsp')
          if not lsp_ok then return end

          -- Override the main LSP on_lines handler that causes most sync issues
          if lsp._changetracking and lsp._changetracking.send_changes then
            local original_send_changes = lsp._changetracking.send_changes
            lsp._changetracking.send_changes = function(client, bufnr, changes, offset_encoding)
              -- Validate all inputs before proceeding
              if not client or not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end

              local ok, result = pcall(original_send_changes, client, bufnr, changes, offset_encoding)
              if not ok then
                -- Silent error logging to avoid UI disruption
                vim.api.nvim_err_writeln("LSP sync error (non-fatal): " .. tostring(result))
              end
              return result
            end
          end

          -- Protect incremental_changes function that triggers most sync errors
          if lsp.incremental_changes then
            local original_incremental_changes = lsp.incremental_changes
            lsp.incremental_changes = function(bufnr, changedtick, firstline, lastline, new_lastline, old_byte_size)
              -- Validate buffer state
              if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                return {}
              end

              local ok, result = pcall(original_incremental_changes, bufnr, changedtick, firstline, lastline, new_lastline, old_byte_size)
              if not ok then
                vim.api.nvim_err_writeln("LSP incremental changes error (non-fatal): " .. tostring(result))
                return {}
              end
              return result or {}
            end
          end

          -- Protect the sync module at a lower level
          local sync_ok, sync = pcall(require, 'vim.lsp.sync')
          if sync_ok and sync then
            -- Wrap compute_diff to handle nil line issues
            if sync.compute_diff then
              local original_compute_diff = sync.compute_diff
              sync.compute_diff = function(prev_lines, curr_lines, start_line_idx, end_line_idx, offset_encoding)
                -- Comprehensive input validation
                if not prev_lines or not curr_lines then
                  return {}
                end

                -- Check for nil lines in arrays
                local function validate_lines(lines)
                  if type(lines) ~= 'table' then return false end
                  for i, line in ipairs(lines) do
                    if line == nil then
                      return false
                    end
                  end
                  return true
                end

                if not validate_lines(prev_lines) or not validate_lines(curr_lines) then
                  return {}
                end

                local ok, result = pcall(original_compute_diff, prev_lines, curr_lines, start_line_idx, end_line_idx, offset_encoding)
                if not ok then
                  vim.api.nvim_err_writeln("LSP compute_diff error (non-fatal): " .. tostring(result))
                  return {}
                end
                return result or {}
              end
            end

            -- Wrap apply_text_edits to handle line_ending issues
            if sync.apply_text_edits then
              local original_apply_text_edits = sync.apply_text_edits
              sync.apply_text_edits = function(text_edits, bufnr, offset_encoding)
                if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not text_edits then
                  return
                end

                local ok, result = pcall(original_apply_text_edits, text_edits, bufnr, offset_encoding)
                if not ok then
                  vim.api.nvim_err_writeln("LSP apply_text_edits error (non-fatal): " .. tostring(result))
                end
                return result
              end
            end
          end

          -- Protect changetracking module initialization
          local changetracking_ok, changetracking = pcall(require, 'vim.lsp._changetracking')
          if changetracking_ok and changetracking then
            if changetracking.init then
              local original_init = changetracking.init
              changetracking.init = function(client, bufnr)
                -- Validate buffer before initializing change tracking
                if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                  return
                end

                local ok, result = pcall(original_init, client, bufnr)
                if not ok then
                  vim.api.nvim_err_writeln("LSP changetracking init error (non-fatal): " .. tostring(result))
                end
                return result
              end
            end
          end

          -- Set up a global error handler for any remaining LSP sync issues
          local original_on_error = vim.lsp.handlers['window/logMessage'] or function() end
          vim.lsp.handlers['window/logMessage'] = function(err, result, ctx, config)
            -- Filter out sync-related error spam
            if result and result.message and type(result.message) == 'string' then
              local msg = result.message:lower()
              if msg:match('sync') or msg:match('prev_line') or msg:match('line_ending') or msg:match('nil value') then
                -- Log silently instead of showing to user
                vim.api.nvim_err_writeln("LSP sync message (filtered): " .. result.message)
                return
              end
            end
            return original_on_error(err, result, ctx, config)
          end
        end

        -- Apply the comprehensive protection
        setup_lsp_sync_protection()

        -- Enable diagnostic configuration
        vim.diagnostic.config({
          virtual_text = false,  -- Disable inline diagnostic text
          float = {
            source = "always",  -- Show source in floating window
            border = "rounded",
          },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = "󰅚",
              [vim.diagnostic.severity.WARN] = "󰀪",
              [vim.diagnostic.severity.HINT] = "󰌶",
              [vim.diagnostic.severity.INFO] = "",
            },
          },
          underline = true,     -- Underline diagnostic text
          update_in_insert = false, -- Don't update diagnostics in insert mode
          severity_sort = true, -- Sort diagnostics by severity
        })
      '';

      servers = {
        # https://nix-community.github.io/nixvim/plugins/lsp/
        ansiblels = {
          enable = true;
          package = pkgs.unstable.ansible-language-server;
        };
        astro = {
          enable = false;
          package = pkgs.unstable.astro-language-server;
        };
        bashls = {
          enable = true;
          package = pkgs.unstable.bash-language-server;
        };
        beancount = {
          enable = false;
          package = pkgs.unstable.beancount-language-server;
        };
        biome = {
          enable = false;
          package = pkgs.unstable.biome;
        };
        ccls = {
          # C/C++/Objective-C language server
          enable = true;
          package = pkgs.unstable.ccls;
        };
        clangd = {
          enable = true;
          package = pkgs.unstable.clang-tools;
        };
        clojure_lsp = {
          enable = false;
          package = pkgs.unstable.clojure-lsp;
        };
        cmake = {
          enable = true;
          package = pkgs.unstable.cmake-language-server;
        };
        csharp_ls = {
          enable = false;
          package = pkgs.unstable.csharp-ls; # NOT AVAILABLE on DARWIN
        };
        cssls = {
          enable = true;
          package = pkgs.unstable.nodePackages.vscode-langservers-extracted; # CSS language server
        };
        dagger = {
          enable = false;
          package = pkgs.unstable.dagger;
        };
        dartls = {
          enable = false;
          package = pkgs.unstable.dart;
        };
        denols = {
          enable = false;
          package = pkgs.unstable.deno;
        };
        dhall_lsp_server = {
          enable = false;
          package = pkgs.unstable.dhall-lsp-server;
        };
        digestif = {
          enable = false;
          package = pkgs.unstable.texlivePackages.digestif;
        };
        dockerls = {
          enable = true;
          package = pkgs.unstable.dockerfile-language-server-nodejs;
        };
        efm = {
          enable = true;
          package = pkgs.unstable.efm-langserver;
        };
        elixirls = {
          enable = false;
          package = pkgs.unstable.elixir-ls;
        };
        elmls = {
          enable = false;
          package = pkgs.unstable.elmPackages.elm-language-server;
        };
        emmet_ls = {
          enable = false;
          package = pkgs.unstable.emmet-ls;
        };
        eslint = {
          enable = true; # Disable eslint language server
          # package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
        };
        fsautocomplete = {
          enable = false;
          package = pkgs.unstable.fsautocomplete; # DOESN'T COMPILE ON DARWIN
        };
        futhark_lsp = {
          enable = false;
          package = pkgs.unstable.futhark;
        };
        gdscript = {
          enable = false;
          package = pkgs.unstable.godot;
        };
        gleam = {
          enable = false;
          package = pkgs.unstable.gleam;
        };
        gopls = {
          enable = true;
          package = pkgs.unstable.gopls;
        };
        graphql = {
          enable = false;
          package = pkgs.unstable.nodePackages.graphql-language-service-cli;
        };
        hls = {
          enable = false;
          package = pkgs.unstable.haskell-language-server;
        };
        html = {
          enable = true;
          package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
        };
        htmx = {
          enable = true;
          package = pkgs.unstable.htmx-lsp;
        };
        intelephense = {
          enable = false;
          package = pkgs.unstable.nodePackages.intelephense;
        };
        java_language_server = {
          # USING JDTLS instead!
          enable = false;
          package = pkgs.unstable.java-language-server;
        };
        jdtls = {
          enable = true;
          package = pkgs.jdt-language-server;
          autostart = true;
        };
        jsonls = {
          enable = true;
          package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
        };
        julials = {
          enable = false;
          package = pkgs.unstable.julia-bin;
        };
        kotlin_language_server = {
          enable = false;
          package = pkgs.unstable.kotlin-language-server;
        };
        leanls = {
          enable = false;
          package = pkgs.unstable.lean4;
        };
        ltex = {
          enable = false;
          package = pkgs.unstable.ltex-ls;
        };
        lua_ls = {
          enable = true;
          package = pkgs.unstable.lua-language-server;
        };
        m68k = {
          enable = false;
          # package = # NO UPSTREAM PACKAGE
        };
        markdown_oxide = {
          enable = true;
          package = pkgs.unstable.markdown-oxide;
        };
        marksman = {
          enable = true;
          package = pkgs.unstable.marksman;
        };
        matlab_ls = {
          enable = false;
          package = pkgs.unstable.matlab-language-server;
        };
        mdx_analyzer = {
          enable = false;
          # package = # NO UPSTREAM PACKAGE
        };
        mesonlsp = {
          enable = true;
          package = pkgs.unstable.mesonlsp;
        };
        metals = {
          enable = false;
          package = pkgs.unstable.metals;
        };
        millet = {
          enable = false;
          # package = # NO UPSTREAM PACKAGE
        };
        mint = {
          enable = false;
          package = pkgs.unstable.mint;
        };
        mlir_lsp_server = {
          enable = false;
          package = pkgs.unstable.llvmPackages.mlir;
        };
        mlir_pdll_lsp_server = {
          enable = false;
          package = pkgs.unstable.llvmPackages.mlir;
        };
        nil_ls = {
          enable = true;
          package = pkgs.unstable.nil;
          settings = {
            "nil" = {
              nix = {
                maxMemoryMB = 2560;
                flake = {
                  autoArchive = true;
                  autoEvalInputs = true;
                };
              };
            };
          };
        };
        nixd = {
          enable = true;
          package = pkgs.unstable.nixd;
        };
        nushell = {
          enable = false;
          package = pkgs.unstable.nushell;
        };
        ols = {
          enable = false;
          package = pkgs.unstable.ols; # FAILED
        };
        omnisharp = {
          enable = false;
          package = pkgs.unstable.omnisharp-roslyn;
        };
        perlpls = {
          enable = false;
          package = pkgs.unstable.perl534Packages.PLS;
        };
        pest_ls = {
          enable = false;
          package = pkgs.unstable.pest-language-server;
        };
        phpactor = {
          enable = false;
          package = pkgs.unstable.phpactor;
        };
        prismals = {
          enable = false;
          package = pkgs.unstable.nodePackages."@prisma/language-server";
        };
        prolog_ls = {
          enable = false;
          package = pkgs.unstable.swiProlog;
        };
        pylsp = {
          enable = false;
          package = pkgs.unstable.python3Packages.python-lsp-server;
        };
        pylyzer = {
          enable = false;
          package = pkgs.unstable.pylyzer;
        };
        pyright = {
          #lsp - pyright
          #linter - flake8
          #formatter - black
          enable = true;
          package = pkgs.unstable.pyright;
        };
        rnix = {
          enable = false; # using nil_ls instead!
          package = pkgs.unstable.rnix-lsp;
        };
        ruff_lsp = {
          enable = false;
          package = pkgs.unstable.ruff-lsp;
        };
        rust_analyzer = {
          enable = true;
          package = pkgs.unstable.rust-analyzer;
          installCargo = false;
          installRustc = false;
        };
        solargraph = {
          enable = false;
          package = pkgs.unstable.solargraph;
        };
        sourcekit = {
          # Swift and C-based languages
          enable = false; # requires compilation of swift? NO THANKS!
          # package = pkgs.unstable.sourcekit-lsp; # FAILED TO COMPILE ON NIXOS
        };
        svelte = {
          enable = false;
          package = pkgs.unstable.nodePackages.svelte-language-server;
        };
        tailwindcss = {
          enable = true;
          package = pkgs.unstable.nodePackages."@tailwindcss/language-server";
        };
        taplo = {
          enable = true; # for TOML
          package = pkgs.unstable.taplo;
          autostart = true;
          filetypes = [ "toml" ]; # Include .toml files
        };
        templ = {
          enable = false;
          package = pkgs.unstable.templ;
        };
        terraformls = {
          enable = false;
          package = pkgs.unstable.terraform-ls;
        };
        texlab = {
          enable = true;
          package = pkgs.unstable.texlab;
        };
        ts_ls = {
          enable = true;
          package = pkgs.unstable.nodePackages.typescript-language-server;
        };
        typst_lsp = {
          enable = false;
          package = pkgs.unstable.typst-lsp;
        };
        vls = {
          enable = false;
          package = pkgs.unstable.vls;
        };
        volar = {
          enable = false;
          package = pkgs.unstable.nodePackages."@volar/vue-language-server";
        };
        vuels = {
          enable = false;
          package = pkgs.unstable.nodePackages.vue-language-server;
        };
        yamlls = {
          enable = true;
          package = pkgs.unstable.yaml-language-server;
        };
        zls = {
          enable = false;
          package = pkgs.unstable.zls;
        };
      };
    };

    # LSP related plugins
    lsp-format.enable = true;
    lsp-lines = {
      enable = true;
      # Configuration will use defaults since currentLine option is deprecated
    };

    # lspkind is configured in completion.nix to avoid duplication

    # Note: Mason plugins are not available in nixvim
    # We manage LSP servers directly through nixpkgs (see servers section above)
  };
}
