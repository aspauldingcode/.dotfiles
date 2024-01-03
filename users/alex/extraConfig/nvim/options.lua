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
o.tabstop = 8
o.shiftwidth = 8
o.softtabstop = 8
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

-- Indent selected text right with Tab
vim.api.nvim_set_keymap('x', '<Tab>', [[>gv]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Tab>', [[>gv]], { noremap = true, silent = true })

-- Indent selected text left with Shift + Tab
vim.api.nvim_set_keymap('x', '<S-Tab>', [[<gv]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<S-Tab>', [[<gv]], { noremap = true, silent = true })

-- Word Processor Mode
local wordProcessorModeActive = false

function ToggleWordProcessorMode()
    if wordProcessorModeActive then
        vim.bo.formatoptions = ''
        vim.bo.textwidth = 0
        vim.bo.smartindent = false
        vim.wo.spell = false
        vim.bo.spelllang = ''
        vim.bo.expandtab = true
        wordProcessorModeActive = false
    else
        vim.bo.formatoptions = 't1'
        vim.bo.textwidth = 80
        vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })
        vim.bo.smartindent = true
        vim.wo.spell = true
        vim.bo.spelllang = 'en_us'
        vim.bo.expandtab = false
        -- Set custom status line hint
        vim.wo.statusline = 'WordProcessorMode: Press z= for spellcheck suggestions'
        wordProcessorModeActive = true
    end
end

vim.cmd('command! WP lua ToggleWordProcessorMode()')

-- Misc Improvements
o.smartcase = true
o.ttimeoutlen = 5
o.compatible = false
o.autoread = true
o.incsearch = true
o.hidden = true
o.shortmess = "atI"
