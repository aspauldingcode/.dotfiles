{
  config,
  pkgs,
  ...
}:
{
  programs.nixvim.plugins = {
    # Enable which-key for better keybind discovery
    which-key = {
      enable = true;
      settings = {
        delay = 500;
        expand = 1;
        notify = false;
        preset = "modern";
        replace = {
          desc = [
            [
              "<space>"
              "SPACE"
            ]
            [
              "<leader>"
              "SPACE"
            ]
            [
              "<cr>"
              "RETURN"
            ]
            [
              "<tab>"
              "TAB"
            ]
          ];
        };
        spec = [
          {
            __unkeyed-1 = "<leader>f";
            group = "Find";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "Trouble";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "Code";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>z";
            group = "Folds";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>a";
            group = "AI";
            icon = "󰧑 ";
          }
        ];
        win = {
          border = "rounded";
          padding = [
            1
            2
          ];
        };
      };
    };
  };

  programs.nixvim.extraConfigLua = ''
    -- Keybind Hints System
    -- This creates a mapping of commands to their associated keybinds
    -- and shows hints when typing commands in the command line

    local keybind_hints = {}

    -- OS Detection
    local is_mac = vim.loop.os_uname().sysname == "Darwin"
    local cmd_symbol = is_mac and " " or "Ctrl"  -- Apple logo for macOS
    local leader_symbol = "󱁐"  -- Leader key symbol

    -- Function to format keybind display
    local function format_keybind(key, desc)
      -- Replace platform-specific keys
      if key:match("<D%-") and is_mac then
        key = key:gsub("<D%-", cmd_symbol .. "+")
      elseif key:match("<C%-") and not is_mac then
        key = key:gsub("<C%-", cmd_symbol .. "+")
      elseif key:match("<C%-") and is_mac then
        -- On macOS, show Ctrl as Ctrl (not Cmd) when it's actually Ctrl
        key = key:gsub("<C%-", "Ctrl+")
      end

      -- Replace leader key
      key = key:gsub("<leader>", leader_symbol .. " ")
      key = key:gsub("<Leader>", leader_symbol .. " ")

      -- Clean up other special keys
      key = key:gsub("<CR>", "↵")
      key = key:gsub("<Tab>", "⇥")
      key = key:gsub("<S%-", "⇧")
      key = key:gsub("<A%-", "⌥")
      key = key:gsub("[<>]", "")

      return key
    end

    -- Build command-to-keybind mapping from our NixVim configuration
    local function build_command_mapping()
      local mapping = {}

      -- File tree commands
      mapping["NvimTreeToggle"] = {
        keys = {"<leader>e", "<C-b>", "<C-S-b>"},
        desc = "Toggle file tree"
      }
      mapping["NvimTreeClose"] = {
        keys = {"<leader>e", "<C-b>"},
        desc = "Close file tree"
      }
      mapping["NvimTreeOpen"] = {
        keys = {"<leader>e", "<C-b>"},
        desc = "Open file tree"
      }

      -- Telescope commands
      mapping["Telescope find_files"] = {
        keys = {"<leader>ff", is_mac and "<D-d>" or "<C-d>"},
        desc = "Find files"
      }
      mapping["Telescope live_grep"] = {
        keys = {"<leader>fg", is_mac and "<D-f>" or "<C-f>"},
        desc = "Live grep"
      }
      mapping["Telescope buffers"] = {
        keys = {"<leader>fb"},
        desc = "Find buffers"
      }
      mapping["Telescope help_tags"] = {
        keys = {"<leader>fh"},
        desc = "Find help tags"
      }
      mapping["Telescope oldfiles"] = {
        keys = {"<leader>fr"},
        desc = "Find recent files"
      }
      mapping["Telescope commands"] = {
        keys = {"<leader>fc"},
        desc = "Find commands"
      }

      -- Trouble commands
      mapping["Trouble diagnostics toggle"] = {
        keys = {"<leader>xx"},
        desc = "Diagnostics (Trouble)"
      }
      mapping["Trouble diagnostics toggle filter.buf=0"] = {
        keys = {"<leader>xX"},
        desc = "Buffer Diagnostics (Trouble)"
      }
      mapping["Trouble symbols toggle focus=false"] = {
        keys = {"<leader>cs"},
        desc = "Symbols (Trouble)"
      }
      mapping["Trouble lsp toggle focus=false win.position=right"] = {
        keys = {"<leader>cl"},
        desc = "LSP Definitions / references (Trouble)"
      }
      mapping["Trouble loclist toggle"] = {
        keys = {"<leader>xL"},
        desc = "Location List (Trouble)"
      }
      mapping["Trouble qflist toggle"] = {
        keys = {"<leader>xQ"},
        desc = "Quickfix List (Trouble)"
      }

      -- AI commands
      mapping["AvanteChat"] = {
        keys = {"<leader>ac"},
        desc = "Open Avante AI chat"
      }
      mapping["AvanteToggle"] = {
        keys = {"<leader>at"},
        desc = "Toggle Avante AI chat"
      }
      mapping["AvanteAsk"] = {
        keys = {"<leader>aa"},
        desc = "Ask Avante AI a question"
      }
      mapping["AvanteExplain"] = {
        keys = {},
        desc = "Ask Avante to explain code"
      }
      mapping["AvanteOptimize"] = {
        keys = {},
        desc = "Ask Avante to optimize code"
      }
      mapping["AvanteDebug"] = {
        keys = {},
        desc = "Ask Avante to debug code"
      }
      mapping["AvanteTest"] = {
        keys = {},
        desc = "Ask Avante to write tests"
      }
      mapping["AvanteDoc"] = {
        keys = {},
        desc = "Ask Avante to document code"
      }

      -- Color reload
      mapping["ReloadColors"] = {
        keys = {"<leader>tc"},
        desc = "Reload colors from ~/colors.toml"
      }

      -- Common vim commands
      mapping["undo"] = {
        keys = {is_mac and "<D-z>" or "<C-z>"},
        desc = "Undo"
      }
      mapping["redo"] = {
        keys = {is_mac and "<D-y>" or "<C-y>", is_mac and "<D-S-Z>" or "<C-S-Z>"},
        desc = "Redo"
      }

      -- Text alignment
      mapping["left"] = {
        keys = {is_mac and "<D-l>" or "<C-l>"},
        desc = "Align text left"
      }
      mapping["center"] = {
        keys = {is_mac and "<D-e>" or "<C-e>"},
        desc = "Center text"
      }
      mapping["right"] = {
        keys = {is_mac and "<D-r>" or "<C-r>"},
        desc = "Align text right"
      }

      return mapping
    end

    -- Initialize the mapping
    local command_mapping = build_command_mapping()

    -- Function to get keybind hint for a command
    local function get_keybind_hint(cmd)
      -- Clean up the command (remove leading colon and whitespace)
      cmd = cmd:gsub("^:?%s*", "")

      -- Look for exact matches first
      if command_mapping[cmd] then
        local mapping = command_mapping[cmd]
        local keys = {}
        for _, key in ipairs(mapping.keys) do
          table.insert(keys, format_keybind(key, mapping.desc))
        end
        return table.concat(keys, " or ")
      end

      -- Look for partial matches (for commands with arguments)
      for command, mapping in pairs(command_mapping) do
        if cmd:match("^" .. vim.pesc(command)) then
          local keys = {}
          for _, key in ipairs(mapping.keys) do
            table.insert(keys, format_keybind(key, mapping.desc))
          end
          return table.concat(keys, " or ")
        end
      end

      return nil
    end

    -- Custom completion function that shows keybind hints
    local function enhanced_cmdline_complete(input, line, pos)
      local hint = get_keybind_hint(line)
      if hint then
        -- Store the hint to be displayed
        vim.g.current_keybind_hint = hint
        -- Trigger a redraw to show the hint
        vim.schedule(function()
          vim.cmd("redrawstatus")
        end)
      else
        vim.g.current_keybind_hint = nil
      end

      -- Return normal completion
      return vim.fn.getcompletion(input, 'cmdline')
    end

    -- Set up command line completion with keybind hints
    vim.api.nvim_create_autocmd("CmdlineEnter", {
      pattern = ":",
      callback = function()
        vim.g.current_keybind_hint = nil
        vim.g.showing_keybind_hints = true
      end
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
      pattern = ":",
      callback = function()
        vim.g.current_keybind_hint = nil
        vim.g.showing_keybind_hints = false
        vim.cmd("redrawstatus")

        -- Close any existing hint window
        if vim.g.keybind_hint_win and vim.api.nvim_win_is_valid(vim.g.keybind_hint_win) then
          vim.api.nvim_win_close(vim.g.keybind_hint_win, true)
          vim.g.keybind_hint_win = nil
        end
      end
    })

    -- Custom command line completion that shows keybind hints
    local original_complete = vim.fn.complete
    local function enhanced_complete(startcol, matches)
      -- Get current command line
      local cmdline = vim.fn.getcmdline()
      local hint = get_keybind_hint(cmdline)

      -- If we have a hint, add it as a completion item
      if hint and type(matches) == "table" then
        -- Add hint as the first completion item with special formatting
        local hint_item = {
          word = "",
          abbr = "󰌌 " .. hint,
          menu = "keybind",
          info = "Available keybinding for this command",
          kind = "keybind",
          dup = 0
        }
        table.insert(matches, 1, hint_item)
      end

      return original_complete(startcol, matches)
    end

    -- Override the complete function
    vim.fn.complete = enhanced_complete

    -- Set up command line completion with custom function
    vim.o.completeopt = "menu,menuone,noselect,preview"

    -- Enhanced command line navigation with arrow keys and hjkl
    local function setup_cmdline_navigation()
      -- Command line mappings for better navigation
      vim.keymap.set('c', '<C-j>', '<Down>', { desc = 'Move down in command completion' })
      vim.keymap.set('c', '<C-k>', '<Up>', { desc = 'Move up in command completion' })
      vim.keymap.set('c', '<C-h>', '<Left>', { desc = 'Move left in command line' })
      vim.keymap.set('c', '<C-l>', '<Right>', { desc = 'Move right in command line' })

      -- Arrow key navigation in command line
      vim.keymap.set('c', '<Down>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-n>'
        else
          return '<Down>'
        end
      end, { expr = true, desc = 'Navigate completion menu or command history' })

      vim.keymap.set('c', '<Up>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-p>'
        else
          return '<Up>'
        end
      end, { expr = true, desc = 'Navigate completion menu or command history' })

      -- Enhanced Tab navigation
      vim.keymap.set('c', '<Tab>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-n>'
        elseif vim.fn.getcmdline():match('^%s*$') then
          return '<Tab>'
        else
          return '<C-n>'
        end
      end, { expr = true, desc = 'Next completion item' })

      vim.keymap.set('c', '<S-Tab>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-p>'
        else
          return '<C-p>'
        end
      end, { expr = true, desc = 'Previous completion item' })

      -- Page up/down for long completion lists
      vim.keymap.set('c', '<C-d>', function()
        if vim.fn.pumvisible() == 1 then
          -- Move down 5 items in completion menu
          return '<C-n><C-n><C-n><C-n><C-n>'
        else
          return '<C-d>'
        end
      end, { expr = true, desc = 'Page down in completion menu' })

      vim.keymap.set('c', '<C-u>', function()
        if vim.fn.pumvisible() == 1 then
          -- Move up 5 items in completion menu
          return '<C-p><C-p><C-p><C-p><C-p>'
        else
          return '<C-u>'
        end
      end, { expr = true, desc = 'Page up in completion menu' })

      -- Accept completion with Enter
      vim.keymap.set('c', '<CR>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-y>'
        else
          return '<CR>'
        end
      end, { expr = true, desc = 'Accept completion or execute command' })

      -- Cancel completion with Escape
      vim.keymap.set('c', '<Esc>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-e><Esc>'
        else
          return '<Esc>'
        end
      end, { expr = true, desc = 'Cancel completion or exit command mode' })
    end

    -- Initialize command line navigation
    setup_cmdline_navigation()

    -- Create a more visible way to show hints during command typing
    local hint_ns = vim.api.nvim_create_namespace("keybind_hints")

    -- Function to show floating hint window
    local function show_hint_window(hint)
      if not hint or hint == "" then return end

      -- Create a small floating window with the hint
      local buf = vim.api.nvim_create_buf(false, true)
      local hint_text = "󰌌 " .. hint
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {hint_text})

      -- Set buffer options
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

      -- Calculate window position (bottom right of screen)
      local width = #hint_text + 2
      local height = 1
      local row = vim.o.lines - vim.o.cmdheight - 2
      local col = vim.o.columns - width - 2

      -- Create floating window
      local win = vim.api.nvim_open_win(buf, false, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        focusable = false,
        zindex = 1000
      })

      -- Set window highlight
      vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Comment,FloatBorder:Comment')

      -- Store window ID for cleanup
      vim.g.keybind_hint_win = win

      -- Auto-close after a delay
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        vim.g.keybind_hint_win = nil
      end, 3000) -- Close after 3 seconds
    end

    -- Enhanced command line change handler with floating window
    vim.api.nvim_create_autocmd("CmdlineChanged", {
      pattern = ":",
      callback = function()
        -- Close any existing hint window
        if vim.g.keybind_hint_win and vim.api.nvim_win_is_valid(vim.g.keybind_hint_win) then
          vim.api.nvim_win_close(vim.g.keybind_hint_win, true)
          vim.g.keybind_hint_win = nil
        end

        local cmdline = vim.fn.getcmdline()
        local hint = get_keybind_hint(cmdline)

        if hint ~= vim.g.current_keybind_hint then
          vim.g.current_keybind_hint = hint
          vim.cmd("redrawstatus")

          -- Show floating hint window
          if hint and #cmdline > 2 then -- Only show for commands longer than 2 chars
            show_hint_window(hint)
          end
        end
      end
    })

    -- Add keybind hint to statusline
    local function get_cmdline_hint()
      if vim.g.showing_keybind_hints and vim.g.current_keybind_hint then
        return "  " .. vim.g.current_keybind_hint
      end
      return ""
    end

    -- Make the function globally available
    _G.get_cmdline_hint = get_cmdline_hint

    -- Create a user command to test the keybind hints
    vim.api.nvim_create_user_command('KeybindHints', function()
      print("Available keybind hints:")
      for cmd, mapping in pairs(command_mapping) do
        local keys = {}
        for _, key in ipairs(mapping.keys) do
          table.insert(keys, format_keybind(key, mapping.desc))
        end
        print(":" .. cmd .. " → " .. table.concat(keys, " or "))
      end
    end, {
      desc = 'Show all available keybind hints'
    })

    -- Also create a command to refresh the mapping (useful for development)
    vim.api.nvim_create_user_command('RefreshKeybindHints', function()
      command_mapping = build_command_mapping()
      print("Keybind hints refreshed!")
    end, {
      desc = 'Refresh the keybind hints mapping'
    })
  '';

}
