
{ pkgs, config, lib, inputs, ... }:

# MY NIX CONFIG
{
   nixpkgs = {
    overlays = [
      (final: prev: {
        vimPlugins = prev.vimPlugins // {
          own-onedark-nvim = prev.vimUtils.buildVimPlugin {
            name = "onedark";
            src = inputs.plugin-onedark;
          };
        };
      })
    ];
  };


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
        #{
        #  plugin = vim-numbertoggle;
        #  config = "set number relativenumber";
        #}
        
        {
          plugin = nvim-lspconfig;
          config = toLuaFile ../extraConfig/nvim/plugin/lsp.lua;
        }

        {
          plugin = comment-nvim;
          config = toLua "require(\"Comment\").setup()";
        }

        {
          plugin = gruvbox-nvim;
          config = "colorscheme gruvbox";
        }

        {
          plugin = vim-startify;
          config = "let g:startify_change_to_vcs_root = 0";
        }

        {
          plugin = nvim-colorizer-lua;
          config = ''
            packadd! nvim-colorizer.lua
            lua require 'colorizer'.setup()
          '';
        }
        
        {
          plugin = nvim-cmp;
          config = toLuaFile ../extraConfig/nvim/plugin/cmp.lua;
        }
        
        {
          plugin = telescope-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/telescope.lua;
        }
        neodev-nvim
        telescope-fzf-native-nvim
        cmp_luasnip
        cmp-nvim-lsp
        luasnip
        friendly-snippets
        lualine-nvim
        nvim-web-devicons
        vim-nix
        vim-autoswap
        
        #{ # Using a github repo theme (imported through flake.nix)
          #plugin = own-onedark-nvim;
          #config = "colorscheme onedark";
        #}

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
