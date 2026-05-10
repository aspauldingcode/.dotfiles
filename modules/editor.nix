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
        number = true;         # Show line numbers
        relativenumber = true; # Relative line numbers for logic jumps
        shiftwidth = 2;        # 2 spaces for indentation
        tabstop = 2;           # 2 spaces for tab
        softtabstop = 2;
        expandtab = true;      # Use spaces instead of tabs
        smartindent = true;
        wrap = false;          # Don't wrap lines
        swapfile = false;
        backup = false;
        undofile = true;       # Maintain undo history between sessions
        hlsearch = false;      # Clear search highlight
        incsearch = true;
        termguicolors = true;  # True color support
        scrolloff = 8;         # Keep cursor in the middle
        signcolumn = "yes";
        updatetime = 50;
        completeopt = "menuone,noselect";
      };

      # ── Stable Compatible Lua Config ────────────────────────────
      # Using extraLuaConfig instead of the newer initLua for 25.11 compatibility
      extraLuaConfig = ''
        -- ── AI Agentic Workflow Integration ──────────────────────────
        local ok, cc = pcall(require, "codecompanion")
        if ok then
          cc.setup({
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
        vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = "${config.lib.stylix.colors.withHashtag.base03}" })
        vim.api.nvim_set_hl(0, "Keyword", { italic = true })
        vim.api.nvim_set_hl(0, "Conditional", { italic = true })
        vim.api.nvim_set_hl(0, "Repeat", { italic = true })
        vim.api.nvim_set_hl(0, "Function", { italic = true, bold = true })
        
        -- Nix Specific Highlighting
        vim.api.nvim_set_hl(0, "@variable.nix", { fg = "${config.lib.stylix.colors.withHashtag.base05}" })
        vim.api.nvim_set_hl(0, "@function.call.nix", { fg = "${config.lib.stylix.colors.withHashtag.base0D}" })
      '';

      # ── Plugins ──────────────────────────────────────────────────
      plugins = {
        # Navigation & UI
        lualine.enable = true;
        bufferline.enable = true;
        noice.enable = true;
        notify.enable = true;
        which-key.enable = true;
        neo-tree.enable = true;
        oil.enable = true;
        telescope.enable = true;

        # Treesitter & LSP
        treesitter = {
          enable = true;
          nixGrammars = true;
          settings.highlight.enable = true;
        };
        lsp = {
          enable = true;
          servers = {
            nil_ls.enable = true;
            lua_ls.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
          };
        };

        # Coding & AI
        cmp.enable = true;
        conform-nvim.enable = true; # Formatter
        codecompanion.enable = true; # AI Assistant

        # Utility
        toggleterm.enable = true;
        gitsigns.enable = true;
        mini.enable = true;
      };

      # ── Keymaps ─────────────────────────────────────────────────
      keymaps = [
        { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Toggle Neo-tree"; }
        { mode = "n"; key = "-"; action = "<cmd>Oil<cr>"; options.desc = "Open Oil"; }
        { mode = "n"; key = "<leader>sf"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find Files"; }
        { mode = "n"; key = "<leader>sg"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live Grep"; }
      ];
    };

    home.packages = with pkgs; [
      nixfmt
      stylua
      shfmt
      ruff
    ];
  };
}
