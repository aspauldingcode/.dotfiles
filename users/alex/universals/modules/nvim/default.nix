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

  # nixvim specific dependencies
  home.packages = with pkgs; [];

  programs.nixvim = let
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
  in {
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
    '';

    keymaps = [
      # https://github.com/nix-community/nixvim/tree/main#key-mappings

      # LSP Diagnostic navigation (updated to use new API)
      {
        mode = "n";
        key = "<leader>e";
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
        key =
          if pkgs.stdenv.isDarwin
          then "<D-d>"
          else "<C-d>";
        action = "<cmd>Telescope find_files<CR>";
        options = {
          desc = "Find files (platform key)";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-f>"
          else "<C-f>";
        action = "<cmd>Telescope live_grep<CR>";
        options = {
          desc = "Live grep (platform key)";
        };
      }

      # Text alignment keymaps
      {
        mode = "i";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-l>"
          else "<C-l>";
        action = "<Esc>:left<CR>";
        options = {
          desc = "Align text left";
        };
      }
      {
        mode = "i";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-e>"
          else "<C-e>";
        action = "<Esc>:center<CR>";
        options = {
          desc = "Center text";
        };
      }
      {
        mode = "i";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-r>"
          else "<C-r>";
        action = "<Esc>:right<CR>";
        options = {
          desc = "Align text right";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-l>"
          else "<C-l>";
        action = ":left<CR>";
        options = {
          desc = "Align text left";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-e>"
          else "<C-e>";
        action = ":center<CR>";
        options = {
          desc = "Center text";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-r>"
          else "<C-r>";
        action = ":right<CR>";
        options = {
          desc = "Align text right";
        };
      }

      # Undo/Redo keymaps
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-z>"
          else "<C-z>";
        action = ":undo<CR>";
        options = {
          desc = "Undo";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-y>"
          else "<C-y>";
        action = ":redo<CR>";
        options = {
          desc = "Redo";
        };
      }
      {
        mode = "n";
        key =
          if pkgs.stdenv.isDarwin
          then "<D-S-Z>"
          else "<C-S-Z>";
        action = ":redo<CR>";
        options = {
          desc = "Redo (alternative)";
        };
      }

      # File tree keymaps
      {
        mode = "n";
        key = "<C-b>";
        action = "<cmd>NvimTreeToggle<CR>";
        options = {
          desc = "Toggle file tree";
        };
      }
      {
        mode = "n";
        key = "<C-S-b>";
        action = "<cmd>NvimTreeToggle<CR>";
        options = {
          desc = "Toggle file tree (alternative)";
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
    ];

    colorschemes.base16 = {
      enable = true;
      colorscheme = let
        inherit (config.colorScheme) palette;
      in {
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
