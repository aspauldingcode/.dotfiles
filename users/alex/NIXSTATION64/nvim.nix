{ pkgs, config, lib, ... }:

# MY NIX CONFIG
{
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  vimdiffAlias = true;
  plugins = with pkgs.vimPlugins [
    nvim-tree-lua
    zoxide-vim
    #nerdtree
    #vim-nerdtree-syntax-highlight
    windows-nvim
    nvim-lspconfig
    nvim-treesitter.withAllGrammars
    gruvbox-material
    mini-nvim
    {
      plugin = pkgs.vimPlugins.vim-startify;
      config = "let g:startify_change_to_vcs_root = 0";
    }
    { # lua example plugin
      plugin = pkgs.vimPlugins.nvim-colorizer-lua;
      config = ''
        packadd! nvim-colorizer.lua
        lua require 'colorizer'.setup()
      '';
    }
  ];
};
}
