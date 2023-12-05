local o = vim.opt
local g = vim.g

-- disable netrw at the very start of your init.lua
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

g.mapleader = ' '
g.maplocalleader = ' '
o.showcmd = true

-- set clipboard to use system clipboard
o.clipboard = 'unnamedplus'

-- Indentation
o.smartindent = true
o.autoindent = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true
o.signcolumn = 'yes'
o.wrap = false
o.textwidth = 80
o.formatoptions = "t"

-- Use mouse
o.mouse = "a"

-- UI settings
o.number = true
o.relativenumber = true
o.termguicolors = true
o.updatetime = 300
o.cursorline = true
vim.cmd('filetype plugin indent on')

-- Get rid of annoying viminfo file
o.viminfo = ""
o.viminfofile = "NONE"

-- Keybinds
local function map(mode, combo, mapping, opts)
    local options = {noremap = true}
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, combo, mapping, options)
end
map('n', '<C-p>', ':NvimTreeToggle <CR>', {noremap = true})
map('n', '<C-f>', ':Telescope find_files <CR>', {noremap = true})
map('n', '<C-n>', ':Telescope live_grep <CR>', {noremap = true})

-- Misc Improvements
o.smartcase = true
o.ttimeoutlen = 5
o.compatible = false
o.autoread = true
o.incsearch = true
o.hidden = true
o.shortmess = "atI"
