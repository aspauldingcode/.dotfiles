
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
mini-nvim
vim-visual-multi
vim-nix
vim-lsp-ultisnips
snippets-nvim
vim-snippets
{
  plugin = pkgs.vimPlugins.gruvbox-nvim;
  config = ''
    set background=dark
    colorscheme gruvbox
  '';
}
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
    extraLuaConfig = ''
        -- Map Ctrl+C to copy (yank) assuming you're in visual or visual line mode
        vim.api.nvim_set_keymap('x', '<C-c>', '"+y', { noremap = false })

        -- Map Ctrl+X to cut (dd) in all modes
        vim.api.nvim_set_keymap('n', '<C-x>', ':<C-u>normal! dd<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-x>', '<Esc>:<C-u>normal! dd<CR>', { noremap = true })
        vim.api.nvim_set_keymap('x', '<C-x>', 'd', { noremap = true })
        vim.api.nvim_set_keymap('x', 'd', '<Plug>(v-d)', {})

        -- Map Ctrl+V to paste (put) in all modes
        vim.api.nvim_set_keymap('n', '<C-v>', '"+gP', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-v>', '<C-r>+', { noremap = true })

        -- Map Ctrl+A to select the entire document in all modes
        vim.api.nvim_set_keymap('i', '<C-a>', '<Esc>:noh<CR>ggVG', { noremap = true })
        vim.api.nvim_set_keymap('n', '<C-a>', ':noh<CR>ggVG', { noremap = true })

        -- Map Ctrl+F to run auto-formatting (gg=G) in normal and insert mode
        vim.api.nvim_set_keymap('n', '<C-f>', ':normal! gg=G<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-f>', '<Esc>:normal! gg=G<CR>', { noremap = true })

        -- Map Ctrl+S to save the file in normal and insert mode
        vim.api.nvim_set_keymap('n', '<C-s>', ':w<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-s>', '<C-o>:w<CR>', { noremap = true })
        vim.api.nvim_set_keymap('x', '<C-s>', ':w<CR>', { noremap = true })

        -- Map Ctrl+Q to close the file
        vim.api.nvim_set_keymap('n', '<C-Q>', ':q<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-Q>', '<C-o>:q<CR>', { noremap = true })

        -- Prompt the user for a file to open when pressing Ctrl+O
        vim.api.nvim_set_keymap('n', '<C-o>', ':edit<Space>', { noremap = true })

        -- Map Ctrl+Z to undo
        vim.api.nvim_set_keymap('n', '<C-z>', ':undo<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-z>', '<C-o>:undo<CR>', { noremap = true })

        -- Map Ctrl+Y to redo (alternative: Map Ctrl+Shift+z)
        vim.api.nvim_set_keymap('n', '<C-y>', ':redo<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-y>', '<C-o>:redo<CR>', { noremap = true })
        vim.api.nvim_set_keymap('n', '<C-S-Z>', ':redo<CR>', { noremap = true })
        vim.api.nvim_set_keymap('i', '<C-S-Z>', '<C-o>:redo<CR>', { noremap = true })

        -- Move to the window above the current one using Ctrl+Up
        vim.api.nvim_set_keymap('n', '<C-Up>', '<C-W><Up>', { noremap = true })

        -- Move to the window below the current one using Ctrl+Down
        vim.api.nvim_set_keymap('n', '<C-Down>', '<C-W><Down>', { noremap = true })

        -- Move to the window to the left of the current one using Ctrl+Left
        vim.api.nvim_set_keymap('n', '<C-Left>', '<C-W><Left>', { noremap = true })

        -- Move to the window to the right of the current one using Ctrl+Right
        vim.api.nvim_set_keymap('n', '<C-Right>', '<C-W><Right>', { noremap = true })

        -- Define a function to determine the split type based on the window count
        function AutoTiledSplit()
        local window_count = vim.fn.winnr('$') -- Get the total number of windows

        if window_count % 2 == 0 then
            vim.cmd('split')
        else
            vim.cmd('vsplit')
                end
                end

                -- Map Ctrl+N to create an auto-tiled split and navigate to it
                vim.api.nvim_set_keymap('n', '<C-n>', ':lua AutoTiledSplit()<CR><C-W>w', { noremap = true })

                vim.opt.termguicolors = true

                vim.opt.smartindent = true

                vim.opt.wrap = false

                vim.opt.tabstop = 4
                vim.opt.softtabstop = 4
                vim.opt.shiftwidth = 4
    '';
  };
}
