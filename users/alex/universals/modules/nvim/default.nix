{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
# my universal neovim configuration with Nix Syntax using NixVim!
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./treesitter.nix
    ./lsp.nix
    ./formatting.nix
    ./ui.nix
    ./completion.nix
    ./git.nix
    ./telescope.nix
    ./avante.nix
    ./markdown.nix
    ./keybind-hints.nix
    # ./extras.nix
  ];

  # nixvim specific dependencies
  home.packages = with pkgs; [ ];

  programs.nixvim =
    let
      toLua = str: ''
        lua << EOF
        ${str}
        EOF
      '';
      toLuaFile = file: ''
        lua << EOF
        ${builtins.readFile file}
        EOF
      '';
    in
    {
      enable = true;
      # Use unstable packages for nixvim to ensure all packages are available
      nixpkgs.pkgs = pkgs.unstable;
      # Temporarily disabled due to air-formatter issue in man page generation
      # The man page generation tries to reference pkgs.air-formatter which doesn't exist in stable
      # TODO: Re-enable when nixvim fixes the package reference or when air-formatter is in stable
      enableMan = false; # enable man pages for nixvim options.

      opts = {
        number = true; # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 4; # Tab width should be 4
        termguicolors = true;
        # System clipboard integration
        clipboard = "unnamedplus"; # Use system clipboard for all yank/delete/put operations
        # Folding options for nvim-origami (let origami handle foldmethod/foldexpr)
        foldcolumn = "0"; # Disable built-in fold column (statuscol handles it)
        foldlevel = 99; # High fold level for origami
        foldlevelstart = 99; # Start with all folds open
        foldenable = true; # Enable folding
        # Note: foldmethod and foldexpr are handled by origami's useLspFoldsWithTreesitterFallback

        # Enhanced command line completion
        wildmenu = true; # Enable enhanced command line completion
        wildmode = "longest:full,full"; # Command line completion mode
        wildoptions = "pum"; # Use popup menu for completion
        pumheight = 15; # Maximum number of items in popup menu
        pumwidth = 30; # Minimum width of popup menu
        pumblend = 10; # Transparency for popup menu
      };

      globals = {
        # Leader keys must be set before any keymaps
        mapleader = " ";
        maplocalleader = " ";
      };

      extraConfigLua = ''
        -- Print a little welcome message when nvim is opened!
        -- print("Hello world!")

        -- Remove any conflicting keymaps that might be set in options.lua
        pcall(vim.keymap.del, 'n', '<C-b>')
        pcall(vim.keymap.del, 'n', '<C-S-b>')

        -- All my configuration options for nvim:
        ${builtins.readFile ./options.lua}

        -- Clean fillchars for statuscol fold handling
        vim.opt.fillchars = {
          fold = " ",
          foldopen = " ",
          foldclose = " ",
          foldsep = " ",
          diff = "╱",
          eob = " ",
          vert = "│",  -- Add vertical separator for window splits
        }

        -- Ensure window separators are visible and properly styled
        vim.opt.laststatus = 3  -- Global statusline
        vim.opt.winbar = ""     -- No winbar by default

        -- Window separator styling
        vim.cmd([[
          highlight WinSeparator guifg=#4C566A guibg=NONE
          highlight VertSplit guifg=#4C566A guibg=NONE
        ]])

        -- Let origami handle fold method and expressions
        -- No manual fold configuration needed

        -- Simple hot-reload for color scheme
        local function reload_colors()
          -- Parse colors.toml to detect light/dark variant
          local colors_file = vim.fn.expand("~/colors.toml")
          local variant = "dark"  -- default

          if vim.fn.filereadable(colors_file) == 1 then
            local content = vim.fn.readfile(colors_file)
            for _, line in ipairs(content) do
              local variant_match = line:match('variant = "([^"]*)"')
              if variant_match then
                variant = variant_match
                break
              end
            end
          end

          -- Set background based on variant
          vim.o.background = variant

          -- Since we're using base16 plugin with custom setup, we need to re-source the config
          -- to pick up the new background setting and re-apply colors
          vim.cmd("source ~/.config/nvim/init.lua")

          -- Force refresh of UI elements that might not update automatically
          vim.cmd("redraw!")
          vim.cmd("doautocmd ColorScheme")

          -- Refresh tabline and statusline
          vim.cmd("redrawtabline")
          vim.cmd("redrawstatus")

          -- Force barbar to refresh (it should automatically pick up colorscheme changes)
          -- barbar respects colorscheme changes better than bufferline
          local barbar_ok = pcall(require, 'barbar')
          if barbar_ok then
            -- barbar automatically updates with colorscheme changes, no manual refresh needed
            vim.cmd("doautocmd User BarbarStart")
          end

          print("🎨 Colors reloaded (" .. variant .. " mode)")
        end

        -- Create user command for manual reload
        vim.api.nvim_create_user_command('ReloadColors', reload_colors, {
          desc = 'Reload current colorscheme with updated background'
        })

        -- Auto-reload when returning to neovim (checks for theme changes)
        vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"}, {
          pattern = "*",
          callback = function()
            local colors_file = vim.fn.expand("~/colors.toml")
            if vim.fn.filereadable(colors_file) == 1 then
              -- Read the actual file content to detect changes (since it's a nix symlink)
              local content = vim.fn.readfile(colors_file)
              local content_hash = vim.fn.join(content, "\n")

              -- Initialize if not set
              if not vim.g.last_colors_content then
                vim.g.last_colors_content = content_hash
                return
              end

              -- Check if content changed (not just timestamp, since it's a symlink)
              if content_hash ~= vim.g.last_colors_content then
                print("🔄 Auto-reloading colors (theme changed)")
                reload_colors()
                vim.g.last_colors_content = content_hash
              end
            end
          end,
          desc = "Auto-reload colors when returning to neovim or entering buffers"
        })

        -- Initialize last content check (for symlink detection)
        local colors_file = vim.fn.expand("~/colors.toml")
        if vim.fn.filereadable(colors_file) == 1 then
          local content = vim.fn.readfile(colors_file)
          vim.g.last_colors_content = vim.fn.join(content, "\n")
        else
          vim.g.last_colors_content = ""
        end

        -- Set up ColorScheme autocommand to refresh barbar (though it should auto-update)
        vim.api.nvim_create_autocmd("ColorScheme", {
          pattern = "*",
          callback = function()
            -- barbar should automatically pick up colorscheme changes
            -- but we can trigger a refresh just in case
            local barbar_ok = pcall(require, 'barbar')
            if barbar_ok then
              vim.defer_fn(function()
                vim.cmd("doautocmd User BarbarStart")
              end, 10)
            end
          end,
          desc = "Refresh barbar when colorscheme changes"
        })

        -- Also set up a timer-based check as fallback (every 2 seconds)
        local timer = vim.loop.new_timer()
        timer:start(2000, 2000, vim.schedule_wrap(function()
          local colors_file = vim.fn.expand("~/colors.toml")
          if vim.fn.filereadable(colors_file) == 1 then
            local content = vim.fn.readfile(colors_file)
            local content_hash = vim.fn.join(content, "\n")

            if vim.g.last_colors_content and content_hash ~= vim.g.last_colors_content then
              print("🔄 Auto-reloading colors (timer check)")
              reload_colors()
              vim.g.last_colors_content = content_hash
            end
          end
        end))
      '';

      keymaps = [
        # https://github.com/nix-community/nixvim/tree/main#key-mappings

        # LSP Diagnostic navigation (updated to use new API)
        {
          mode = "n";
          key = "<leader>d";
          action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          options = {
            desc = "Show diagnostic error messages";
          };
        }
        {
          mode = "n";
          key = "[d";
          action = "<cmd>lua vim.diagnostic.jump({count = -1, float = true})<CR>";
          options = {
            desc = "Go to previous diagnostic message";
          };
        }
        {
          mode = "n";
          key = "]d";
          action = "<cmd>lua vim.diagnostic.jump({count = 1, float = true})<CR>";
          options = {
            desc = "Go to next diagnostic message";
          };
        }
        {
          mode = "n";
          key = "[D";
          action = "<cmd>lua vim.diagnostic.jump({count = -1, float = true, severity = vim.diagnostic.severity.ERROR})<CR>";
          options = {
            desc = "Go to previous error";
          };
        }
        {
          mode = "n";
          key = "]D";
          action = "<cmd>lua vim.diagnostic.jump({count = 1, float = true, severity = vim.diagnostic.severity.ERROR})<CR>";
          options = {
            desc = "Go to next error";
          };
        }
        {
          mode = "n";
          key = "<leader>q";
          action = "<cmd>lua vim.diagnostic.setloclist()<CR>";
          options = {
            desc = "Open diagnostics list";
          };
        }

        # Trouble plugin keymaps
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<CR>";
          options = {
            desc = "Diagnostics (Trouble)";
          };
        }
        {
          mode = "n";
          key = "<leader>xX";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
          options = {
            desc = "Buffer Diagnostics (Trouble)";
          };
        }
        {
          mode = "n";
          key = "<leader>cs";
          action = "<cmd>Trouble symbols toggle focus=false<CR>";
          options = {
            desc = "Symbols (Trouble)";
          };
        }
        {
          mode = "n";
          key = "<leader>cl";
          action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>";
          options = {
            desc = "LSP Definitions / references / ... (Trouble)";
          };
        }
        {
          mode = "n";
          key = "<leader>xL";
          action = "<cmd>Trouble loclist toggle<CR>";
          options = {
            desc = "Location List (Trouble)";
          };
        }
        {
          mode = "n";
          key = "<leader>xQ";
          action = "<cmd>Trouble qflist toggle<CR>";
          options = {
            desc = "Quickfix List (Trouble)";
          };
        }

        # Snippet navigation
        {
          mode = [
            "i"
            "s"
          ];
          key = "<C-k>";
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
          key = "<C-j>";
          action = "<cmd>lua require('luasnip').jump(-1)<CR>";
          options = {
            desc = "Jump to previous snippet placeholder";
          };
        }

        # Origami fold management keymaps
        {
          mode = "n";
          key = "<leader>zr";
          action = "zR";
          options = {
            desc = "Open all folds";
          };
        }
        {
          mode = "n";
          key = "<leader>zm";
          action = "zM";
          options = {
            desc = "Close all folds";
          };
        }
        {
          mode = "n";
          key = "<leader>zh";
          action = "zc";
          options = {
            desc = "Close fold under cursor";
          };
        }
        {
          mode = "n";
          key = "<leader>zl";
          action = "zo";
          options = {
            desc = "Open fold under cursor";
          };
        }
        {
          mode = "n";
          key = "<leader>za";
          action = "za";
          options = {
            desc = "Toggle fold under cursor";
          };
        }

        # Telescope keymaps
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<CR>";
          options = {
            desc = "Find files";
          };
        }
        {
          mode = "n";
          key = "<leader>fg";
          action = "<cmd>Telescope live_grep<CR>";
          options = {
            desc = "Live grep";
          };
        }
        {
          mode = "n";
          key = "<leader>fb";
          action = "<cmd>Telescope buffers<CR>";
          options = {
            desc = "Find buffers";
          };
        }
        {
          mode = "n";
          key = "<leader>fh";
          action = "<cmd>Telescope help_tags<CR>";
          options = {
            desc = "Find help tags";
          };
        }
        {
          mode = "n";
          key = "<leader>fr";
          action = "<cmd>Telescope oldfiles<CR>";
          options = {
            desc = "Find recent files";
          };
        }
        {
          mode = "n";
          key = "<leader>fc";
          action = "<cmd>Telescope commands<CR>";
          options = {
            desc = "Find commands";
          };
        }

        # Platform-specific keymaps (macOS uses Cmd, others use Ctrl)
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-d>" else "<C-d>";
          action = "<cmd>Telescope find_files<CR>";
          options = {
            desc = "Find files (platform key)";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-f>" else "<C-f>";
          action = "<cmd>Telescope live_grep<CR>";
          options = {
            desc = "Live grep (platform key)";
          };
        }

        # Text alignment keymaps
        {
          mode = "i";
          key = if pkgs.stdenv.isDarwin then "<D-l>" else "<C-l>";
          action = "<Esc>:left<CR>";
          options = {
            desc = "Align text left";
          };
        }
        {
          mode = "i";
          key = if pkgs.stdenv.isDarwin then "<D-e>" else "<C-e>";
          action = "<Esc>:center<CR>";
          options = {
            desc = "Center text";
          };
        }
        {
          mode = "i";
          key = if pkgs.stdenv.isDarwin then "<D-r>" else "<C-r>";
          action = "<Esc>:right<CR>";
          options = {
            desc = "Align text right";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-l>" else "<C-l>";
          action = ":left<CR>";
          options = {
            desc = "Align text left";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-e>" else "<C-e>";
          action = ":center<CR>";
          options = {
            desc = "Center text";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-r>" else "<C-r>";
          action = ":right<CR>";
          options = {
            desc = "Align text right";
          };
        }

        # Undo/Redo keymaps
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-z>" else "<C-z>";
          action = ":undo<CR>";
          options = {
            desc = "Undo";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-y>" else "<C-y>";
          action = ":redo<CR>";
          options = {
            desc = "Redo";
          };
        }
        {
          mode = "n";
          key = if pkgs.stdenv.isDarwin then "<D-S-Z>" else "<C-S-Z>";
          action = ":redo<CR>";
          options = {
            desc = "Redo (alternative)";
          };
        }

        # File tree keymaps
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>NvimTreeToggle<CR>";
          options = {
            desc = "Toggle file tree";
          };
        }
        {
          mode = "n";
          key = "<C-b>";
          action = "<cmd>NvimTreeToggle<CR>";
          options = {
            desc = "Toggle file tree (Ctrl-b)";
          };
        }
        {
          mode = "n";
          key = "<C-S-b>";
          action = "<cmd>NvimTreeToggle<CR>";
          options = {
            desc = "Toggle file tree (Ctrl-Shift-b)";
          };
        }

        # Select All keymaps
        {
          mode = "n";
          key = "<C-a>";
          action = "<cmd>normal! ggVG<CR>";
          options = {
            desc = "Select all";
          };
        }
        {
          mode = "v";
          key = "<C-a>";
          action = "<Esc><cmd>normal! ggVG<CR>";
          options = {
            desc = "Select all";
          };
        }
        {
          mode = "x";
          key = "<C-a>";
          action = "<Esc><cmd>normal! ggVG<CR>";
          options = {
            desc = "Select all";
          };
        }
        {
          mode = "i";
          key = "<C-a>";
          action = "<Esc><cmd>normal! ggVG<CR>";
          options = {
            desc = "Select all";
          };
        }

        # Indentation in visual mode
        {
          mode = "x";
          key = "<Tab>";
          action = ">gv";
          options = {
            desc = "Indent selection";
          };
        }
        {
          mode = "v";
          key = "<Tab>";
          action = ">gv";
          options = {
            desc = "Indent selection";
          };
        }
        {
          mode = "x";
          key = "<S-Tab>";
          action = "<gv";
          options = {
            desc = "Unindent selection";
          };
        }
        {
          mode = "v";
          key = "<S-Tab>";
          action = "<gv";
          options = {
            desc = "Unindent selection";
          };
        }

        # Avante AI chat keymap
        {
          mode = "n";
          key = "<leader>ac";
          action = "<cmd>AvanteChat<CR>";
          options = {
            desc = "Open Avante AI chat";
          };
        }

        # Line wrapping toggle
        {
          mode = "n";
          key = "<leader>w";
          action = "<cmd>lua ToggleWrap()<CR>";
          options = {
            desc = "Toggle line wrapping";
          };
        }
        {
          mode = "n";
          key = "<leader>tc";
          action = ":ReloadColors<CR>";
          options = {
            silent = true;
            desc = "Reload colors from ~/colors.toml";
          };
        }
      ];

      # Colorscheme is handled by base16 plugin configuration below
      # Set background based on color scheme variant
      opts.background = if config.colorScheme.variant == "light" then "light" else "dark";

      colorschemes.base16 = {
        enable = true;
        colorscheme =
          let
            inherit (config.colorScheme) palette;
          in
          {
            # use nix-colors
            base00 = "#${palette.base00}";
            base01 = "#${palette.base01}";
            base02 = "#${palette.base02}";
            base03 = "#${palette.base03}";
            base04 = "#${palette.base04}";
            base05 = "#${palette.base05}";
            base06 = "#${palette.base06}";
            base07 = "#${palette.base07}";
            base08 = "#${palette.base08}";
            base09 = "#${palette.base09}";
            base0A = "#${palette.base0A}";
            base0B = "#${palette.base0B}";
            base0C = "#${palette.base0C}";
            base0D = "#${palette.base0D}";
            base0E = "#${palette.base0E}";
            base0F = "#${palette.base0F}";
          };
      };
    };
}
