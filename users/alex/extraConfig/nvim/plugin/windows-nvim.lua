-- nvim-window animations

-- Ensure the required plugins are installed
require('middleclass')
require('animation')

-- Set recommended options for animations
vim.o.winwidth = 10
vim.o.winminwidth = 10
vim.o.equalalways = false

-- Setup windows.nvim
require('windows').setup({
    autowidth = {
        enable = true,
        winwidth = 5,
        filetype = {
            help = 2,
        },
    },
    ignore = {
        buftype = { "quickfix" },
        filetype = { "NvimTree", "neo-tree", "undotree", "gundo" }
    },
    animation = {
        enable = true,
        duration = 300,
        fps = 30,
        easing = "in_out_sine"
    }
})

-- Key mappings for windows.nvim commands
local function cmd(command)
    return table.concat({ '<Cmd>', command, '<CR>' })
end

-- Press Ctrl+w then z to maximize the window
vim.keymap.set('n', '<C-w>z', cmd 'WindowsMaximize')
-- Press Ctrl+w then _ to maximize the window vertically
vim.keymap.set('n', '<C-w>_', cmd 'WindowsMaximizeVertically')
-- Press Ctrl+w then | to maximize the window horizontally
vim.keymap.set('n', '<C-w>|', cmd 'WindowsMaximizeHorizontally')
-- Press Ctrl+w then = to equalize the window sizes
vim.keymap.set('n', '<C-w>=', cmd 'WindowsEqualize')
