require('nvim-treesitter.configs').setup {
    ensure_installed = ""; -- "maintained", -- "all" || "maintained"
    auto_install = false;
    highlight = {
        enable = true    -- false disables the entire extension.
    },
    indent = {
        enable = true
    },
    context = {
        enable = true, -- Enable nvim-treesitter-context
    },
    autotag = {
        enable = true, -- Enable nvim-ts-autotag
    },
    rainbow = {
        enable = true, -- Enable nvim-ts-rainbow
    },
}

