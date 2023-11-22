
{ pkgs, config, lib, inputs, ... }:

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
        
        # LSP Related
        {
          plugin = nvim-lspconfig;
          config = toLuaFile ../extraConfig/nvim/plugin/lsp.lua;
        }
        # nvim-jdtls # FIXME: y u no worky? >:(
        # lsp-status-nvim # FIXME: What about lspinfo?
        # lazy-lsp-nvim # FIXME: LEARN MORE
        # asyncomplete-lsp-vim # FIXME: Learn more

        # Auto-Completion
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
            lua require 'colorizer'.setup(})
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

        # Visual Fixes
        lualine-nvim # FIXME: https://github.com/nvim-lualine/lualine.nvim
        indentLine # lines to identify codeblocks

        # Behavior Fixes
        vim-autoswap

        neodev-nvim # FIXME: WTF is neodev-nvim? NEEDED
        
        # Fuzzy Search Tool
        telescope-fzf-native-nvim # FIXME: How do I use?

        # Syntax Highlighting
        vim-nix # better highlighting for nix files
        
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
          ]));
          config = toLuaFile ../extraConfig/nvim/plugin/treesitter.lua;
        }
    ];

    extraLuaConfig = '' 
      ${builtins.readFile ../extraConfig/nvim/options.lua}
    '';
  };
}
