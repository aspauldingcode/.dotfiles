local scrollview = require('scrollview')

local function setup(config)
    config = config or {}
    local api = vim.api
    local fn = vim.fn
    local signs = require('gitsigns.config').config.signs

    local defaults = {
        enabled = true,
        hide_full_add = true,
        only_first_line = false,
        add_priority = 90,
        change_priority = 90,
        delete_priority = 90,
        add_highlight = signs.add.hl or 'DiffAdd',
        change_highlight = signs.change.hl or 'DiffChange',
        delete_highlight = signs.delete.hl or 'DiffDelete',
        add_symbol = signs.add.text or fn.nr2char(0x2503),
        change_symbol = signs.change.text or fn.nr2char(0x2503),
        delete_symbol = signs.delete.text or fn.nr2char(0x2581)
    }

    for key, val in pairs(defaults) do
        config[key] = config[key] or val
    end

    local group = 'gitsigns'

    local add = scrollview.register_sign_spec({
        extend = true,
        group = group,
        highlight = config.add_highlight,
        priority = config.add_priority,
        symbol = config.add_symbol,
    }).name

    local change = scrollview.register_sign_spec({
        extend = true,
        group = group,
        highlight = config.change_highlight,
        priority = config.change_priority,
        symbol = config.change_symbol,
    }).name

    local delete = scrollview.register_sign_spec({
        extend = true,
        group = group,
        highlight = config.delete_highlight,
        priority = config.delete_priority,
        symbol = config.delete_symbol,
    }).name

    scrollview.set_sign_group_state(group, config.enabled)

    local active_bufnrs = {}

    api.nvim_create_autocmd('User', {
        pattern = 'GitSignsUpdate',
        callback = function()
            local gitsigns = require('gitsigns')
            for bufnr, _ in pairs(active_bufnrs) do
                if api.nvim_buf_is_valid(bufnr) then
                    vim.b[bufnr][add] = {}
                    vim.b[bufnr][change] = {}
                    vim.b[bufnr][delete] = {}
                end
            end
            for _, tabpage in ipairs(api.nvim_list_tabpages()) do
                local tabwins = api.nvim_tabpage_list_wins(tabpage)
                for _, winid in ipairs(tabwins) do
                    local bufnr = api.nvim_win_get_buf(winid)
                    local hunks = gitsigns.get_hunks(bufnr) or {}
                    if not vim.tbl_isempty(hunks) then
                        active_bufnrs[bufnr] = true
                    end
                    local lines_add = {}
                    local lines_change = {}
                    local lines_delete = {}
                    for _, hunk in ipairs(hunks) do
                        if hunk.type == 'add' then
                            local full = hunk.added.count >= api.nvim_buf_line_count(bufnr)
                            if not config.hide_full_add or not full then
                                local first = hunk.added.start
                                local last = hunk.added.start
                                if not config.only_first_line then
                                    last = last + hunk.added.count - 1
                                end
                                for line = first, last do
                                    table.insert(lines_add, line)
                                end
                            end
                        elseif hunk.type == 'change' then
                            local first = hunk.added.start
                            local last = first
                            if not config.only_first_line then
                                last = last + hunk.added.count - 1
                                if hunk.added.count > hunk.removed.count then
                                    last = last - (hunk.added.count - hunk.removed.count)
                                end
                            end
                            for line = first, last do
                                table.insert(lines_change, line)
                            end
                            if hunk.added.count > hunk.removed.count then
                                first = hunk.added.start + hunk.removed.count
                                last = first
                                if not config.only_first_line then
                                    last = last + hunk.added.count - hunk.removed.count - 1
                                end
                                for line = first, last do
                                    table.insert(lines_add, line)
                                end
                            end
                        elseif hunk.type == 'delete' then
                            table.insert(lines_delete, hunk.added.start)
                        end
                    end
                    vim.b[bufnr][add] = lines_add
                    vim.b[bufnr][change] = lines_change
                    vim.b[bufnr][delete] = lines_delete
                end
            end
            if not scrollview.is_sign_group_active(group) then return end
            vim.cmd('silent! ScrollViewRefresh')
        end
    })

    pcall(function()
        require('gitsigns').refresh()
    end)
end

return {
    setup = setup
}
