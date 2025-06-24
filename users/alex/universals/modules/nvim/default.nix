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
    inputs.nixvim.homeManagerModules.nixvim
    ./treesitter.nix
    ./lsp.nix
    ./formatting.nix
    ./ui.nix
    ./completion.nix
    ./git.nix
    ./telescope.nix
    ./avante.nix
    ./markdown.nix
    # ./extras.nix
  ];

  nixpkgs.config.allowUnsupportedSystemPredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "swiftformat"
      "sourcekit-lsp"
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
      nixpkgs.pkgs = pkgs.unstable;
      enableMan = true; # enable man pages for nixvim options.

      opts = {
        number = true; # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 4; # Tab width should be 4
        termguicolors = true;
        # Folding options for nvim-origami (let origami handle foldmethod/foldexpr)
        foldcolumn = "0"; # Disable built-in fold column (statuscol handles it)
        foldlevel = 99; # High fold level for origami
        foldlevelstart = 99; # Start with all folds open
        foldenable = true; # Enable folding
        # Note: foldmethod and foldexpr are handled by origami's useLspFoldsWithTreesitterFallback
      };

      globals = {
        # Leader keys must be set before any keymaps
        mapleader = " ";
        maplocalleader = " ";
      };

      extraConfigLua = ''
        -- Print a little welcome message when nvim is opened!
        -- print("Hello world!")

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
        }

        -- Let origami handle fold method and expressions
        -- No manual fold configuration needed
      '';

      keymaps = [
        # https://github.com/nix-community/nixvim/tree/main#key-mappings

        # LSP Diagnostic navigation (updated to use new API)
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          options.desc = "Show diagnostic error messages";
        }
        {
          mode = "n";
          key = "[d";
          action = "<cmd>lua vim.diagnostic.jump({count = -1, float = true})<CR>";
          options.desc = "Go to previous diagnostic message";
        }
        {
          mode = "n";
          key = "]d";
          action = "<cmd>lua vim.diagnostic.jump({count = 1, float = true})<CR>";
          options.desc = "Go to next diagnostic message";
        }
        {
          mode = "n";
          key = "[D";
          action = "<cmd>lua vim.diagnostic.jump({count = -1, float = true, severity = vim.diagnostic.severity.ERROR})<CR>";
          options.desc = "Go to previous error";
        }
        {
          mode = "n";
          key = "]D";
          action = "<cmd>lua vim.diagnostic.jump({count = 1, float = true, severity = vim.diagnostic.severity.ERROR})<CR>";
          options.desc = "Go to next error";
        }
        {
          mode = "n";
          key = "<leader>q";
          action = "<cmd>lua vim.diagnostic.setloclist()<CR>";
          options.desc = "Open diagnostics list";
        }

        # Trouble plugin keymaps
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<CR>";
          options.desc = "Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xX";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
          options.desc = "Buffer Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>cs";
          action = "<cmd>Trouble symbols toggle focus=false<CR>";
          options.desc = "Symbols (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>cl";
          action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>";
          options.desc = "LSP Definitions / references / ... (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xL";
          action = "<cmd>Trouble loclist toggle<CR>";
          options.desc = "Location List (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xQ";
          action = "<cmd>Trouble qflist toggle<CR>";
          options.desc = "Quickfix List (Trouble)";
        }

        # AI and Completion keymaps
        {
          mode = "n";
          key = "<leader>ai";
          action = "<cmd>Copilot panel<CR>";
          options.desc = "Open Copilot panel";
        }
        {
          mode = "n";
          key = "<leader>at";
          action = "<cmd>Copilot toggle<CR>";
          options.desc = "Toggle Copilot";
        }
        {
          mode = "n";
          key = "<leader>as";
          action = "<cmd>Copilot status<CR>";
          options.desc = "Copilot status";
        }

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

        # Origami fold management keymaps
        {
          mode = "n";
          key = "<leader>zr";
          action = "zR";
          options.desc = "Open all folds";
        }
        {
          mode = "n";
          key = "<leader>zm";
          action = "zM";
          options.desc = "Close all folds";
        }
        {
          mode = "n";
          key = "<leader>zh";
          action = "zc";
          options.desc = "Close fold under cursor";
        }
        {
          mode = "n";
          key = "<leader>zl";
          action = "zo";
          options.desc = "Open fold under cursor";
        }
        {
          mode = "n";
          key = "<leader>za";
          action = "za";
          options.desc = "Toggle fold under cursor";
        }
      ];

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
