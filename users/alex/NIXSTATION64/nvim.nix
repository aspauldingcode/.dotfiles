
{ pkgs, config, ... }:

{
  programs.neovim = 
  let 
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in 
  {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
        # LSP
        {
          plugin = nvim-lspconfig;
          config = toLuaFile ../extraConfig/nvim/plugin/lsp.lua;
        }

        { 
          plugin = nvim-jdtls;
          config = toLua ''
          local config = {
            cmd = {'/home/alex/.config/nvim/jdt-language-server-1.9.0-202203031534/bin/jdtls'},
            root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
          }
          require('jdtls').start_or_attach(config)
          '';
        }

        # FIXME: y u no worky? >:(
        # lsp-status-nvim # FIXME: What about lspinfo?
        # lazy-lsp-nvim # FIXME: LEARN MORE
        # asyncomplete-lsp-vim # FIXME: Learn more
        {
          plugin = nvim-cmp;
          config = toLuaFile ../extraConfig/nvim/plugin/cmp.lua;
        }
        # cmp-nvim-lsp # FIXME: Learn more
        # cmp-nvim-lsp-document-symbol 
        # cmp-nvim-lsp-signature-help

        {
          plugin = comment-nvim;
          config = toLua "require(\"Comment\").setup()";
        }

        {
          plugin = vim-startify;
          config = "let g:startify_change_to_vcs_root = 0";
        }

        {
          plugin = nvim-colorizer-lua; # relies on AutoCmd
          config = ''
          packadd! nvim-colorizer.lua
          lua require 'colorizer'.setup()
          '';
        }

        {
          plugin = telescope-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/telescope.lua;
        }

        # File Tree
        {
          plugin = nvim-tree-lua;
          config = toLuaFile ../extraConfig/nvim/plugin/nvim-tree.lua;
        }
        nvim-web-devicons # optional, for file icons

        # Code Snippits
        luasnip # FIXME: Do I need this too? NEEDED
        cmp-nvim-lsp # FIXME: What's this? NEEDED
        friendly-snippets 
        cmp_luasnip # completion for lua snippits

        {
          plugin = pkgs.vimPlugins.cmp-nvim-tags;
          config = toLuaFile ../extraConfig/nvim/plugin/cmp-tags.lua;
        }

        {
          plugin = statuscol-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/statuscol.lua;
        }

        # Visual Fixes
        {
          plugin = feline-nvim;
          config = let inherit (config.colorscheme) colors; in
          toLuaFile ../extraConfig/nvim/plugin/feline.lua;
        }

        {
          plugin = winbar-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/winbar.lua;
        }

        {
          plugin = indent-blankline-nvim; # lines to identify codeblocks
          config = toLuaFile ../extraConfig/nvim/plugin/indent-blankline.lua;
        }
        # Behavior Fixes
        vim-autoswap
        neodev-nvim # FIXME: WTF is neodev-nvim? NEEDED

        # Fuzzy Search Tool
        telescope-fzf-native-nvim # FIXME: How do I use?

        # Syntax Highlighting
        vim-nix # better highlighting for nix files

        # Emacs Org for nvim
        {
          plugin = neorg;
          config = toLuaFile ../extraConfig/nvim/plugin/neorg.lua;
        }
        neorg-telescope

        {
          plugin = guess-indent-nvim;
          config = toLua "require(\"guess-indent\").setup()";
        }

        # Git Visual integration
        {
          plugin = gitsigns-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/gitsigns.lua;
        }

        { plugin = gruvbox-nvim;
        config = "colorscheme gruvbox";
      }

      { 
        plugin = lsp_lines-nvim;
        config = toLua ''
        require("lsp_lines").setup()
        vim.diagnostic.config({
          virtual_text = false,
        })
        vim.keymap.set(
          "",
          "<Leader>l",
          require("lsp_lines").toggle,
          { desc = "Toggle lsp_lines" }
          )
          '';        
        }

        {
          plugin = (nvim-treesitter.withPlugins (p: [
            p.tree-sitter-nix
            p.tree-sitter-vim
            p.tree-sitter-bash
            p.tree-sitter-lua
            p.tree-sitter-python
            p.tree-sitter-json
            p.tree-sitter-java
            p.tree-sitter-kotlin
            p.tree-sitter-javascript
            p.tree-sitter-typescript
            p.tree-sitter-swift
            p.tree-sitter-cpp
            p.tree-sitter-c
            p.tree-sitter-objc
            p.tree-sitter-c-sharp
            p.tree-sitter-rust
            p.tree-sitter-go
            p.tree-sitter-sql
            p.tree-sitter-xml
            p.tree-sitter-html
            p.tree-sitter-css
            p.tree-sitter-php
            p.tree-sitter-norg
          ]));
          config = toLuaFile ../extraConfig/nvim/plugin/treesitter.lua;
        }
      ];

      extraLuaConfig = '' 
      ${builtins.readFile ../extraConfig/nvim/options.lua}
      '';
    };
  }
