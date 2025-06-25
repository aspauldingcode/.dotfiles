-- luacheck: globals vim

local vim = vim
local o = vim.opt
local g = vim.g

-- ============================================================================
-- BASIC SETTINGS
-- ============================================================================

-- Disable netrw at the very start
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- Leader keys are now handled by NixVim globals section
-- g.mapleader = ' '
-- g.maplocalleader = ' '

-- UI settings
o.showcmd = true
o.number = true
o.relativenumber = true
o.termguicolors = true
o.updatetime = 300
o.cursorline = false
o.mouse = "a"
o.signcolumn = 'yes'

-- Indentation
o.smartindent = true
o.autoindent = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true

-- Text display
o.wrap = false
o.listchars = 'nbsp:␣,eol:↲,tab:»\\ ,extends:›,precedes:‹,trail:•'
o.showbreak = '↳ '

-- Search and completion
o.smartcase = true
o.incsearch = true

-- Misc improvements
o.ttimeoutlen = 5
o.compatible = false
o.autoread = true
o.hidden = true
o.shortmess = "atI"

-- Clipboard (commented out to restore vim motions)
-- o.clipboard = 'unnamedplus'

-- ============================================================================
-- FOLDING CONFIGURATION
-- ============================================================================

-- Clean fold configuration for nvim-origami
vim.opt.foldtext = "v:lua.get_foldtext()"
vim.opt.foldenable = true
vim.o.foldcolumn = '0' -- Disable built-in fold column (statuscol handles it)
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

-- ============================================================================
-- KEYBINDING HELPER FUNCTIONS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

local is_mac = vim.loop.os_uname().sysname == "Darwin"

local function map_with_cmd_key(mode, combo, mapping, opts)
    if is_mac then
        combo = combo:gsub("<C-", "<D-")
    end
    map(mode, combo, mapping, opts)
end

-- ============================================================================
-- KEYBINDINGS
-- ============================================================================

-- File operations
map_with_cmd_key('n', '<C-d>', ':Telescope find_files <CR>')
map_with_cmd_key('n', '<C-f>', ':Telescope live_grep <CR>')

-- Text alignment
map_with_cmd_key('i', '<C-l>', '<Esc>:left <CR>')   -- align text left
map_with_cmd_key('i', '<C-e>', '<Esc>:center <CR>') -- center text
map_with_cmd_key('i', '<C-r>', '<Esc>:right <CR>')  -- align text right
map_with_cmd_key('n', '<C-l>', ':left <CR>')        -- align text left
map_with_cmd_key('n', '<C-e>', ':center <CR>')      -- center text
map_with_cmd_key('n', '<C-r>', ':right <CR>')       -- align text right

-- Undo/Redo
map_with_cmd_key('n', '<C-z>', ':undo <CR>')
map_with_cmd_key('n', '<C-y>', ':redo <CR>')
map_with_cmd_key('n', '<C-S-Z>', ':redo <CR>')

-- File tree
map('n', '<C-b>', '<Esc>:NvimTreeToggle<CR>')
map('n', '<C-S-b>', '<Esc>:NvimTreeToggle<CR>')

-- Select All
map('n', '<C-a>', '<Esc>:normal! ggVG<CR>')
map('v', '<C-a>', '<Esc>:normal! ggVG<CR>')
map('x', '<C-a>', '<Esc>:normal! ggVG<CR>')
map('i', '<C-a>', '<Esc>:normal! ggVG<CR>')

-- Indentation in visual mode
map('x', '<Tab>', '>gv')
map('v', '<Tab>', '>gv')
map('x', '<S-Tab>', '<gv')
map('v', '<S-Tab>', '<gv')

-- Line wrapping toggle
map('n', '<Leader>w', ':lua ToggleWrap()<CR>')

-- ============================================================================
-- AUTOCMDS AND FUNCTIONS
-- ============================================================================

-- Show listchars in visual mode
vim.api.nvim_exec([[
  augroup my_visuallistchars
    autocmd!
    autocmd CursorMoved * if mode() =~# "[vV\<C-v>]" | set list | else | set nolist | endif
  augroup END
]], false)

-- Enable line wrapping at whitespace
vim.api.nvim_win_set_option(0, 'wrap', true)
vim.api.nvim_win_set_option(0, 'linebreak', true)
vim.api.nvim_win_set_option(0, 'breakindent', true)
vim.api.nvim_win_set_option(0, 'showbreak', ' ')

-- Toggle line wrapping function
function ToggleWrap()
    local wrap_state = vim.wo.wrap
    if wrap_state then
        vim.wo.wrap = false
        vim.wo.linebreak = false
        vim.wo.breakindent = false
        print("Wrap disabled")
    else
        vim.wo.wrap = true
        vim.wo.linebreak = true
        vim.wo.breakindent = true
        print("Wrap enabled")
    end
end

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
        print("Word Processor Mode disabled")
    else
        vim.bo.formatoptions = 't1'
        vim.bo.textwidth = 80
        vim.bo.smartindent = true
        vim.wo.spell = true
        vim.bo.spelllang = 'en_us'
        vim.bo.expandtab = false
        vim.wo.statusline = 'WordProcessorMode: Press z= for spellcheck suggestions'
        wordProcessorModeActive = true
        print("Word Processor Mode enabled")
    end
end

-- Commands
vim.cmd('command! -nargs=0 WP lua ToggleWordProcessorMode()')
vim.cmd([[command! -nargs=0 -bar W :]])

-- ============================================================================
-- STARTUP BEHAVIOR
-- ============================================================================

-- Ensure Startify loads first, then open NvimTree
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    callback = function()
        if vim.bo.modifiable and vim.fn.argc() == 0 then
            vim.cmd("Startify")
            vim.cmd("NvimTreeOpen")
            -- Focus back on Startify after NvimTree opens
            vim.defer_fn(function()
                if vim.bo.filetype == "NvimTree" then
                    vim.cmd("wincmd p")
                end
            end, 100)
        end
    end
})

-- ============================================================================
-- HIGHLIGHTS
-- ============================================================================

vim.cmd("highlight FoldColumn guifg=" .. vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Comment')), 'fg'))

-- Enable filetype detection
vim.cmd('filetype plugin indent on')

-- Enable syntax highlighting on macOS
if vim.fn.has('macunix') == 1 then
    vim.cmd("syntax on")
end
