local vim = vim
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
-- o.textwidth = 80
-- o.formatoptions = "t"

-- KEYBINDS
-- How to add ctrl-shift mappings in neovim
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end
  
  -- Control + Shift
  -- map('n', '<C-S-a>', '<cmd>:cna<cr>')
  map('n', '<C-S-b>', '<Esc>:NvimTreeToggle<CR>')
  -- map('n', '<C-S-c>', '<cmd>:cnc<cr>')
  -- map('n', '<C-S-d>', '<cmd>:cnd<cr>')
  -- map('n', '<C-S-e>', '<cmd>:cne<cr>')
  -- map('n', '<C-S-f>', '<cmd>:cnf<cr>')
  -- map('n', '<C-S-g>', '<cmd>:cng<cr>')
  -- map('n', '<C-S-h>', '<cmd>:cnh<cr>')
  -- map('n', '<C-S-i>', '<cmd>:cni<cr>')
  -- map('n', '<C-S-j>', '<cmd>:cnj<cr>')
  -- map('n', '<C-S-k>', '<cmd>:cnk<cr>')
  -- map('n', '<C-S-l>', '<cmd>:cnl<cr>')
  -- map('n', '<C-S-m>', '<cmd>:cnm<cr>')
  -- map('n', '<C-S-n>', '<cmd>:cnn<cr>')
  -- map('n', '<C-S-o>', '<cmd>:cno<cr>')
  -- map('n', '<C-S-p>', '<cmd>:cnp<cr>')
  -- map('n', '<C-S-q>', '<cmd>:cnq<cr>')
  -- map('n', '<C-S-r>', '<cmd>:cnr<cr>')
  -- map('n', '<C-S-s>', '<cmd>:cns<cr>')
  -- map('n', '<C-S-t>', '<cmd>:cnt<cr>')
  -- map('n', '<C-S-u>', '<cmd>:cnu<cr>')
  -- map('n', '<C-S-v>', '<cmd>:cnv<cr>')
  -- map('n', '<C-S-w>', '<cmd>:cnw<cr>')
  -- map('n', '<C-S-x>', '<cmd>:cnx<cr>')
  -- map('n', '<C-S-y>', '<cmd>:cny<cr>')
  -- map('n', '<C-S-z>', '<cmd>:cnz<cr>')
  
  -- Control
  -- map('n', '<C-a>', '<cmd>:cna<cr>')
  map('n', '<C-b>', '<Esc>:NvimTreeToggle<CR>')
  -- map('n', '<C-c>', '<cmd>:cnc<cr>')
  -- map('n', '<C-d>', '<cmd>:cnd<cr>')
  -- map('n', '<C-e>', '<cmd>:cne<cr>')
  -- map('n', '<C-f>', '<cmd>:cnf<cr>')
  -- map('n', '<C-g>', '<cmd>:cng<cr>')
  -- map('n', '<C-h>', '<cmd>:cnh<cr>')
  -- map('n', '<C-i>', '<cmd>:cni<cr>')
  -- map('n', '<C-j>', '<cmd>:cnj<cr>')
  -- map('n', '<C-k>', '<cmd>:cnk<cr>')
  -- map('n', '<C-l>', '<cmd>:cnl<cr>')
  -- map('n', '<C-m>', '<cmd>:cnm<cr>')
  -- map('n', '<C-n>', '<cmd>:cnn<cr>')
  -- map('n', '<C-o>', '<cmd>:cno<cr>')
  -- map('n', '<C-p>', '<cmd>:cnp<cr>')
  -- map('n', '<C-q>', '<cmd>:cnq<cr>')
  -- map('n', '<C-r>', '<cmd>:cnr<cr>')
  -- map('n', '<C-s>', '<cmd>:cns<cr>')
  -- map('n', '<C-t>', '<cmd>:cnt<cr>')
  -- map('n', '<C-u>', '<cmd>:cnu<cr>')
  -- map('n', '<C-v>', '<cmd>:cnv<cr>')
  -- map('n', '<C-w>', '<cmd>:cnw<cr>')
  -- map('n', '<C-x>', '<cmd>:cnx<cr>')
  -- map('n', '<C-y>', '<cmd>:cny<cr>')
  -- map('n', '<C-z>', '<cmd>:cnz<cr>')

-- LSP
-- Map <Leader>f to run LSP format
vim.api.nvim_set_keymap('n', '<Leader>f', '<cmd>lua vim.lsp.buf.format()<CR>',
    { noremap = true, silent = true })

-- Set the keymap
vim.api.nvim_set_keymap('', '<Leader>l', ':lua require("lsp_lines").toggle()<CR>',
    { noremap = true, silent = true, desc = 'Toggle lsp_lines' })

-- Set listchars
vim.o.listchars = 'nbsp:␣,eol:↲,tab:»\\ ,extends:›,precedes:‹,trail:•'

-- Set showbreak
vim.o.showbreak = '↳ '

-- Disable number column in visual mode
vim.api.nvim_exec([[
  augroup my_visuallistchars
    autocmd!
    autocmd CursorMoved * if mode() =~# "[vV\<C-v>]" | set list | else | set nolist | endif
  augroup END
]], false)

-- Use mouse
o.mouse = "a"

-- UI settings
o.number = true
o.relativenumber = true
o.termguicolors = true
o.updatetime = 300
o.cursorline = true
vim.cmd('filetype plugin indent on')

-- Keybinds
local function map(mode, combo, mapping, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, combo, mapping, options)
end
local is_mac = vim.loop.os_uname().sysname == "Darwin"

local function map(mode, combo, mapping, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, combo, mapping, options)
end

local function map_with_cmd_key(mode, combo, mapping, opts)
    if is_mac then
        combo = combo:gsub("<C-", "<D-")
    end
    map(mode, combo, mapping, opts)
end

-- Option 1: Use vim.keymap.set instead of the custom function
-- vim.keymap.set('n', '<C-b>', '<Esc>:NvimTreeToggle<CR>', { noremap = true, silent = true })
-- vim.keymap.set('n', '<D-b>', '<Esc>:NvimTreeToggle<CR>', { noremap = true, silent = true })
map_with_cmd_key('n', '<C-d>', ':Telescope find_files <CR>', { noremap = true })
map_with_cmd_key('n', '<C-f>', ':Telescope live_grep <CR>', { noremap = true })
map_with_cmd_key('i', '<C-l>', '<Esc>:left <CR>', { noremap = true })   -- align text left
map_with_cmd_key('i', '<C-e>', '<Esc>:center <CR>', { noremap = true }) -- center text
map_with_cmd_key('i', '<C-r>', '<Esc>:right <CR>', { noremap = true })  -- align text right
map_with_cmd_key('n', '<C-l>', ':left <CR>', { noremap = true })        -- align text left
map_with_cmd_key('n', '<C-e>', ':center <CR>', { noremap = true })      -- center text
map_with_cmd_key('n', '<C-r>', ':right <CR>', { noremap = true })       -- align text right
map_with_cmd_key('n', '<C-S-Z>', ':redo <CR>', { noremap = true })
map_with_cmd_key('n', '<C-y>', ':redo <CR>', { noremap = true })
map_with_cmd_key('n', '<C-z>', ':undo <CR>', { noremap = true })

-- Enable line wrapping at whitespace
vim.api.nvim_win_set_option(0, 'wrap', true)
vim.api.nvim_win_set_option(0, 'linebreak', true)
vim.api.nvim_win_set_option(0, 'breakindent', true)
vim.api.nvim_win_set_option(0, 'showbreak', ' ')

-- Toggle line wrapping
function ToggleWrap()
    local wrap_state = vim.wo.wrap
    local linebreak_state = vim.wo.linebreak

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

-- Set a key mapping for toggling line wrapping
vim.api.nvim_set_keymap('n', '<Leader>w', [[:lua ToggleWrap()<CR>]], { noremap = true, silent = true })

-- Select All! (in normal, visual, or visual line mode)
vim.api.nvim_set_keymap('n', '<C-a>', '<Esc>:normal! ggVG<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-a>', '<Esc>:normal! ggVG<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<C-a>', '<Esc>:normal! ggVG<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-a>', '<Esc>:normal! ggVG<CR>', { noremap = true, silent = true })
-- ggVG selects all content. gg moves to first line. V starts visual mode. G jumps to last line thereby selecting from first to last line.

-- Copy/Paste (in normal, visual, or visual line mode)
vim.api.nvim_set_keymap('n', '<C-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<C-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-c>', '<Esc>"+y', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<C-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<C-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-v>', '<Esc>"+p', { noremap = true, silent = true })

-- Copy/Paste (in normal, visual, or visual line mode)
vim.api.nvim_set_keymap('n', '<D-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<D-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<D-c>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<D-c>', '<Esc>"+y', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<D-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<D-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<D-v>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<D-v>', '<Esc>"+p', { noremap = true, silent = true })

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

vim.cmd('command! -nargs=0 WP lua ToggleWordProcessorMode()')
vim.cmd([[command! -nargs=0 -bar W :]])

-- Misc Improvements
o.smartcase = true
o.ttimeoutlen = 5
o.compatible = false
o.autoread = true
o.incsearch = true
o.hidden = true
o.shortmess = "atI"

vim.opt.foldtext = "v:lua.get_foldtext()"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldmethod = "expr"
vim.opt.foldenable = false -- Disable folding at startup.

o.signcolumn = 'yes'

vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99

-- Using ufo provider need remap zR and zM. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

vim.cmd("highlight FoldColumn guifg=" .. vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Comment')), 'fg'))

vim.o.statuscolumn = '%=%l%s%C%{foldlevel(v:lnum) > foldlevel(v:lnum - 1) ? (foldclosed(v:lnum) == -1 ? "▼" : "⏵") : " " }'

-- Replace the default fold markers with custom arrows
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ufo = require('ufo')
    local orig_render = ufo.renderFoldedLines

    ufo.renderFoldedLines = function(virtText, lnum, endLnum, width, truncate, ctx)
      local newVirtText = {}
      local suffix = ('  %d '):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0

      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, {chunkText, hlGroup})
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end

      local foldSymbol = '⏵ '
      table.insert(newVirtText, {foldSymbol .. suffix, 'UfoFoldedEllipsis'})
      return newVirtText
    end

    -- Ensure the statuscolumn is updated
    vim.o.statuscolumn = vim.o.statuscolumn
  end,
})

-- Ensure Startify is loaded first and open NvimTree and then focus on Startify
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = function()
    if vim.bo.modifiable and vim.fn.argc() == 0 then
      vim.cmd("Startify")
      vim.cmd("NvimTreeOpen")
      -- Wait for NvimTree to be focused, then move focus back to Startify
      vim.defer_fn(function()
        if vim.bo.filetype == "NvimTree" then
          vim.cmd("wincmd p") -- Move focus back to the previous window (Startify)
        end
      end, 100) -- Adjust the delay (in milliseconds) as needed
    end
  end
})


-- FIXME: Not even working!? :(
-- enable syntax highlighting for nix files with vim-nix on macOS!
if vim.fn.has('macunix') == 1 then
    vim.cmd("syntax on")
end

-- remove "how to disable mouse" popup when using mouse right click
-- o.mouse = 

-- Info notification with fade_in_slide_out animation
-- require("notify")("This is an info notification!", "info", {title = "Info Notification", stages = "fade_in_slide_out"})

-- Warning notification with slide animation
-- require("notify")("This is a warning notification!", "warn", {title = "Warning Notification", stages = "slide"})

-- Error notification with fade animation
-- require("notify")("This is an error notification!", "error", {title = "Error Notification", stages = "fade"})

-- Debug notification with static animation (doesn't show up?)
-- require("notify")("This is a debug notification!", "debug", {title = "Debug Notification", stages = "static"})

-- Trace notification with fade_in_slide_out animation (doesn't show up?)
-- require("notify")("This is a trace notification!", "trace", {title = "Trace Notification", stages = "fade_in_slide_out"})
