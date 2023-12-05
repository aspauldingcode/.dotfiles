local highlight = {
    "CursorColumn",
    "Whitespace",
}

-- vim.g.indent_blankline_char = "."
require("ibl").setup {
    indent = { highlight = highlight, char = "│" },
    whitespace = {
        highlight = highlight,
        remove_blankline_trail = false,
    },
    scope = { enabled = true },

  exclude = {
    filetypes = {'help', 'nvimtree', 'startify', 'dashboard', 'terminal', 'nofile', 'quickfix'},
    buftypes = {'terminal', 'nofile', 'quickfix'},
  }
}
