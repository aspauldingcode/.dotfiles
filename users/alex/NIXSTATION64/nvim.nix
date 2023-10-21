
{ pkgs, config, lib, ... }:

# MY NIX CONFIG
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      zoxide-vim
      vim-pathogen
      {
	plugin = pkgs.vimPlugins.vim-numbertoggle;
      	config = "set number relativenumber";
      }
      # nerdtree
      # vim-nerdtree-syntax-highlight
      windows-nvim
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      gruvbox-material
      mini-nvim
      {
        plugin = pkgs.vimPlugins.vim-startify;
        config = "let g:startify_change_to_vcs_root = 0";
      }
      {
        plugin = pkgs.vimPlugins.nvim-colorizer-lua;
        config = ''
          packadd! nvim-colorizer.lua
          lua require 'colorizer'.setup()
        '';
      }
    ];
  };
}
