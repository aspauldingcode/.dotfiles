{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      inputs,
      lib,
      config,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];

      sops.secrets.openai_api_key = { };

      programs.nixvim = {
        enable = true;
        # Nixvim's inputs pin their own Nixpkgs; our flake makes it `follow`
        # the repo Nixpkgs. Point `nixpkgs.source` at that same input so the
        # override is explicit — silences the "affected by your flake input
        # follows" warning and gives the internal `options.json` derivation a
        # properly-contexted store path.
        nixpkgs.source = inputs.nixpkgs;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        enableMan = false; # Disable man pages to fix the 'options.json' context warning

        # ── Global Options ──────────────────────────────────────────
        globals.mapleader = " ";
        globals.maplocalleader = ",";

        opts = {
          number = true;
          relativenumber = true;
          shiftwidth = 2;
          tabstop = 2;
          expandtab = true;
          smartindent = true;
          wrap = false;
          cursorline = true;
          scrolloff = 8;
          signcolumn = "yes";
          termguicolors = true;
          mouse = "a";
          undofile = true;
          ignorecase = true;
          smartcase = true;
          splitbelow = true;
          splitright = true;
          updatetime = 250;
          timeoutlen = 300;
          clipboard = "unnamedplus";
          completeopt = "menu,menuone,noselect";
          colorcolumn = "80";
          autoread = true;
          sidescroll = 0;
          sidescrolloff = 0;

          # Convert E37/E162 "No write since last change" hard-errors
          # into an interactive `[Y]es / [N]o / [C]ancel` prompt that
          # names each dirty buffer. With `'hidden'` on (Neovim's
          # default), background buffers accumulate without being
          # visible, so the bare error path makes `:q` and `:qa` feel
          # broken whenever any hidden buffer was edited and forgotten
          # — you have to hunt them down with `:ls!` and either `:w`
          # or `:bd!` each one before quit succeeds. Setting
          # `confirm = true` is the standard "modern editor" UX: it
          # asks per dirty buffer and lets you save, discard, or
          # cancel from the prompt. Equivalent to running `:q`
          # commands as `:confirm q` automatically.
          confirm = true;

          # Use swap files but handle them automatically via vim-autoswap
          swapfile = true;
          backup = false;
          writebackup = false;
          shortmess = "filnxtToOFc"; # Removed 'A' to let vim-autoswap detect the prompt
        };

        # ── Colorscheme: applied via mini.base16 (Stylix nixvim target disabled) ──

        # ── Treesitter ──────────────────────────────────────────────
        plugins.treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
            ensure_installed = [
              "bash"
              "c"
              "cpp"
              "css"
              "html"
              "java"
              "javascript"
              "json"
              "lua"
              "markdown"
              "markdown_inline"
              "nix"
              "python"
              "rust"
              "toml"
              "typescript"
              "tsx"
              "vim"
              "vimdoc"
              "yaml"
              "objc"
              "typst"
            ];
          };
        };

        # ── LSP ─────────────────────────────────────────────────────
        plugins.lsp = {
          enable = true;
          inlayHints = false; # Disabled globally to prevent SourceKit-LSP crashes
          servers = {
            # Nix
            nil_ls.enable = true;
            # Python
            pyright.enable = true;
            # TypeScript / JavaScript
            ts_ls.enable = true;
            # C / C++ / Objective-C
            clangd.enable = true;
            # Rust (handled by rustaceanvim, do NOT enable rust_analyzer here)
            # Java — jdtls with DAP debug support enabled on attach
            jdtls = {
              enable = true;
              # Pass the java-debug plugin JAR so jdtls can handle vscode.java.startDebugSession
              extraOptions.init_options.bundles = [
                "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-0.53.2.jar"
              ];
              # After jdtls attaches: register DAP + auto-discover main classes
              onAttach.function = ''
                require('jdtls').setup_dap({ hotcodereplace = 'auto' })
                require('jdtls.dap').setup_dap_main_class_configs()
              '';
            };
            # Typst
            tinymist.enable = true;
            # Lua
            lua_ls.enable = true;
            # HTML / CSS / JSON
            html.enable = true;
            cssls.enable = true;
            jsonls.enable = true;
            # YAML
            yamlls.enable = true;
            # Bash
            bashls.enable = true;
            # Assembly (ARMv7 support)
            asm_lsp.enable = true;
            # Swift
            sourcekit = {
              enable = true;
              # Aggressively disable inlay hints to prevent the -32001 crash
              onAttach.function = ''
                client.server_capabilities.inlayHintProvider = false
              '';
            };
          };
        };

        # ── Rust (rustaceanvim handles rust-analyzer + DAP) ─────────
        plugins.rustaceanvim = {
          enable = true;
          settings.server.default_settings = {
            "rust-analyzer" = {
              check.command = "clippy";
              inlayHints = {
                closingBraceHints.enable = true;
                parameterHints.enable = true;
                typeHints.enable = true;
              };
            };
          };
        };

        # ── Completion (blink.cmp — modern, Rust-powered) ───────────
        plugins.blink-cmp = {
          enable = true;
          # Pin to the overlay-patched derivation. nixvim's default
          # `plugins.blink-cmp.package` snapshots `pkgs.vimPlugins.blink-cmp`
          # at module-import time and somehow misses our host-level
          # `nixpkgs.overlays` override (likely because the nixvim flake
          # carries its own evaluation seam for the plugin set). The fix
          # is to re-route through the user-scope `pkgs` here, which IS
          # overlaid via `home-manager.useGlobalPkgs = true`. Without
          # this line the build closure pulls the upstream-broken
          # `vimplugin-blink.cmp-1.8.0` and the patch in
          # `modules/overlays.nix` becomes a no-op.
          package = pkgs.vimPlugins.blink-cmp;
          settings = {
            # Nix posture for blink.cmp's fuzzy matcher. Pairs with
            # the upstream `fuzzy/download/git.lua` patch applied in
            # `modules/overlays.nix` (vimPlugins.blink-cmp override) —
            # without that patch the Rust path never actually runs on
            # Nix, regardless of these settings, because the upstream
            # git probe crashes when run inside `/nix/store/...`.
            #   - `implementation = "prefer_rust"` — try the Rust
            #     .dylib that nixpkgs builds + symlinks into the
            #     plugin at `target/release/libblink_cmp_fuzzy.dylib`.
            #     If it ever fails to load, fall back to Lua without
            #     the noisy "[blink.cmp] Falling back to Lua…" toast
            #     emitted by the default "prefer_rust_with_warning"
            #     (whose advice — `build = 'cargo build --release'`
            #     in a lazy.nvim spec — has no legitimate analogue
            #     on Nix and would just confuse future-us).
            #   - `prebuilt_binaries.download = false` — blink.cmp
            #     otherwise tries to fetch a pre-built binary from
            #     GitHub releases at runtime when its version
            #     bookkeeping disagrees with the on-disk .dylib. Nix
            #     manages the binary; the runtime fetch path has no
            #     legitimate use here and must never happen.
            fuzzy = {
              implementation = "prefer_rust";
              prebuilt_binaries.download = false;
            };
            # Tab accepts, Esc cancels, Enter does NOT complete
            keymap = {
              preset = "none";
              "<Tab>" = [
                "select_and_accept"
                "snippet_forward"
                "fallback"
              ];
              "<S-Tab>" = [
                "snippet_backward"
                "fallback"
              ];
              "<CR>" = [ "fallback" ]; # Enter types a newline only, never completes
              "<Esc>" = [
                "hide"
                "fallback"
              ];
              "<C-Space>" = [
                "show"
                "show_documentation"
                "hide_documentation"
              ];
              "<C-e>" = [ "hide" ];
              "<C-y>" = [ "select_and_accept" ];
              # Manually invoke minuet (force-fetch an OpenAI
              # completion right now, regardless of the auto-trigger
              # debounce). Returns a function via `make_blink_map()`
              # which blink invokes for this key.
              "<A-y>".__raw = ''require("minuet").make_blink_map()'';
              "<Up>" = [
                "select_prev"
                "fallback"
              ];
              "<Down>" = [
                "select_next"
                "fallback"
              ];
            };
            sources = {
              default = [
                "lsp"
                "path"
                "snippets"
                "buffer"
                "minuet" # AI completion via OpenAI API (see plugins.minuet below)
              ];
              providers.minuet = {
                name = "minuet";
                module = "minuet.blink";
                # Minuet calls OpenAI; blink must not block its main
                # loop on the request — let the source resolve async.
                async = true;
                # Should match `minuet.config.request_timeout * 1000`
                # (minuet's setting is in seconds; this one is in ms).
                timeout_ms = 3000;
                # Bias OpenAI suggestions above LSP/buffer in the
                # menu — they're the most expensive to compute, so
                # surfacing them is the point.
                score_offset = 50;
              };
            };
            signature.enabled = true;
            completion = {
              documentation = {
                auto_show = true;
                auto_show_delay_ms = 200;
              };
              # Avoid double-ghost: minuet has its own `virtualtext`
              # frontend that renders Copilot-style inline previews.
              # If blink ALSO renders ghost text from its top-ranked
              # candidate, the two will overlap and flicker.
              ghost_text.enabled = false;
              # Don't prefetch on every InsertEnter — minuet runs on
              # demand via blink's async source path, so prefetch
              # would burn OpenAI tokens for completions the user
              # never asked for.
              trigger.prefetch_on_insert = false;
              list.selection = {
                # Don't auto-insert, just highlight — press Tab to accept
                preselect = false;
                auto_insert = false;
              };
              menu = {
                # Show keyboard hints in the completion menu border
                border = "rounded";
                draw = {
                  columns = [
                    { "__unkeyed-1" = "label"; }
                    {
                      "__unkeyed-2" = "label_description";
                      gap = 1;
                    }
                    {
                      "__unkeyed-3" = "kind_icon";
                      "__unkeyed-4" = "kind";
                      gap = 1;
                    }
                  ];
                };
              };
            };
          };
        };

        # Industry-standard code snippets
        plugins.friendly-snippets.enable = true;
        plugins.luasnip.enable = true;

        # ── LLM Autocomplete (Inline) — minuet-ai.nvim → OpenAI API ─
        # Replaces `copilot-lua`, which spoke to GitHub Copilot's
        # proprietary endpoint (a separate paid service, NOT the
        # OpenAI API). `minuet-ai.nvim` is a Neovim-native AI
        # completion client that posts to OpenAI's chat-completions
        # endpoint using our sops-managed `openai_api_key`. It plays
        # in two surfaces:
        #
        #   1. As a `blink.cmp` source (wired in
        #      `plugins.blink-cmp.settings.sources` above) — so AI
        #      suggestions appear alongside LSP/buffer entries in
        #      blink's regular completion menu.
        #   2. Via its own `virtualtext` frontend — Copilot-style
        #      ghost-text inline previews with `<M-l>` to accept,
        #      `<M-]>` / `<M-[>` to cycle, `<C-]>` to dismiss
        #      (matching the old copilot-lua bindings to minimise
        #      muscle-memory churn).
        #
        # Key handling: minuet wants a function returning the API
        # key (it calls this on every request). We can't pass the
        # raw secret in Nix (it would land in the world-readable
        # /nix/store), and we won't `vim.env.OPENAI_API_KEY = ...`
        # because that leaks into every nvim subprocess (LSP
        # servers, formatters, terminals). Instead, an IIFE-built
        # closure reads `sops.secrets.openai_api_key.path` once,
        # caches the value, and returns it from the inner function
        # on each call. The secret never leaves nvim's own memory.
        plugins.minuet = {
          enable = true;
          settings = {
            provider = "openai";
            provider_options.openai = {
              # gpt-4o-mini: cheapest production-grade chat model,
              # ~10x cheaper than gpt-4o and fast enough that
              # virtualtext feels live. Swap to `gpt-4.1-mini` or
              # `gpt-4o` if you want stronger completions.
              model = "gpt-4o-mini";
              stream = true;
              api_key.__raw = ''
                (function()
                  local cached
                  return function()
                    if cached and cached ~= "" then return cached end
                    local f = io.open("${config.sops.secrets.openai_api_key.path}", "r")
                    if not f then return "" end
                    cached = (f:read("*a") or ""):gsub("%s+$", "")
                    f:close()
                    return cached
                  end
                end)()
              '';
            };
            # Cost guard: minuet calls OpenAI on every keystroke if
            # auto-trigger is on. Limit to filetypes where AI
            # completion actually pays off — extend this list as
            # needed (e.g. add "markdown" if you want it in prose).
            virtualtext = {
              auto_trigger_ft = [
                "lua"
                "nix"
                "python"
                "rust"
                "go"
                "typescript"
                "typescriptreact"
                "javascript"
                "javascriptreact"
                "c"
                "cpp"
                "java"
                "swift"
                "sh"
                "bash"
                "zsh"
              ];
              keymap = {
                accept = "<M-l>";
                accept_line = "<M-L>";
                accept_n_lines = "<M-z>";
                prev = "<M-[>";
                next = "<M-]>";
                dismiss = "<C-]>";
              };
              # Show the virtualtext only when blink's menu is NOT
              # already showing a candidate — avoids visual collision.
              show_on_completion_menu = false;
            };
            # Throttle / debounce on chatty editing — the defaults
            # (throttle=1500ms, debounce=400ms) are aggressive
            # enough for most flows. Override here if you want.
            request_timeout = 3; # seconds — matches blink timeout_ms above
            n_completions = 1; # one suggestion per request, keeps spend down
            context_window = 16000;
          };
        };

        # Formatting is intentionally delegated to project-local `treefmt`.

        # ── Linting (nvim-lint) ─────────────────────────────────────
        plugins.lint = {
          enable = true;
          lintersByFt = {
            python = [ "ruff" ];
            javascript = [ "eslint_d" ];
            typescript = [ "eslint_d" ];
            nix = [
              "statix"
              "deadnix"
            ];
            sh = [ "shellcheck" ];
            bash = [ "shellcheck" ];
            zsh = [ "shellcheck" ];
            swift = [ "swiftlint" ];
          };
        };

        # ── Autocommands ──────────────────────────────────────────
        autoCmd = [
          # Auto-reload buffers when files change on disk.
          {
            event = [
              "FocusGained"
              "VimResume"
              "BufEnter"
              "WinEnter"
              "CursorHold"
              "CursorHoldI"
              "TermLeave"
              "TermClose"
            ];
            command = "if mode() != 'c' | silent! checktime | endif";
          }
          {
            event = [ "FileChangedShellPost" ];
            callback.__raw = ''
              function()
                vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
              end
            '';
          }
          # Linting
          {
            event = [
              "BufWritePost"
              "InsertLeave"
            ];
            callback.__raw = ''
              function()
                require('lint').try_lint()
              end
            '';
          }
          # Auto-open Neo-tree on directory
          {
            event = [ "VimEnter" ];
            callback.__raw = ''
              function()
                if vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
                  require("neo-tree.command").execute({ action = "show" })
                end
              end
            '';
          }
          # Auto-show diagnostics under the cursor
          {
            event = [
              "CursorHold"
              "CursorHoldI"
            ];
            callback.__raw = ''
              function()
                -- Close popup when moving cursor or typing
                vim.diagnostic.open_float(nil, { 
                  focus = false, 
                  scope = "cursor",
                  close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "WinLeave" }
                })
              end
            '';
          }
        ];

        # ── Debugging (DAP) ─────────────────────────────────────────
        # NOTE: dap-ui is loaded eagerly (no `lazyLoad.settings.cmd`).
        # It used to be `cmd = [ "DapUI" ]`, but two consumers reference
        # `require("dapui")` at init time:
        #   1. The `<leader>du` keymap below (`action.__raw = "..."`
        #      emits the require literally into init.lua, so it runs at
        #      keymap-registration time, not keypress time).
        #   2. The `vim.schedule` block in `extraConfigLua` that wires
        #      DAP auto-open/close listeners — that's `pcall(require,
        #      "dapui")`, so silent-fail if the plugin isn't on the
        #      runtimepath yet.
        # Eager-loading dap-ui adds ~negligible startup cost and makes
        # both code paths trivially correct.
        plugins.dap-ui = {
          enable = true;
          settings = {
            # Auto-open/close the UI when a debug session starts/ends
            icons = {
              expanded = "▾";
              collapsed = "▸";
              current_frame = "▸";
            };
            layouts = [
              {
                elements = [
                  {
                    id = "scopes";
                    size = 0.40;
                  }
                  {
                    id = "breakpoints";
                    size = 0.20;
                  }
                  {
                    id = "stacks";
                    size = 0.20;
                  }
                  {
                    id = "watches";
                    size = 0.20;
                  }
                ];
                position = "left";
                size = 40;
              }
              {
                elements = [
                  {
                    id = "repl";
                    size = 0.5;
                  }
                  {
                    id = "console";
                    size = 0.5;
                  }
                ];
                position = "bottom";
                size = 10;
              }
            ];
          };
        };
        plugins.dap-virtual-text = {
          enable = true;
          settings = {
            enabled = true;
            enabled_commands = true;
            highlight_changed_variables = true;
            highlight_new_as_changed = true;
            show_stop_reason = true;
            commented = false;
            virt_text_pos = "eol"; # Show values at end of line
          };
        };
        plugins.dap = {
          enable = true;
          adapters = {
            executables = {
              python = {
                command = "${pkgs.python3Packages.debugpy}/bin/debugpy-adapter";
              };
            }
            // (
              if isDarwin then
                {
                  lldb = {
                    command = "lldb-dap"; # From Xcode Command Line Tools
                  };
                }
              else
                {
                  gdb = {
                    command = "${pkgs.gdb}/bin/gdb";
                    args = [ "--interpreter=dap" ];
                  };
                }
            );
          };
          configurations = {
            python = [
              {
                name = "Launch file";
                type = "python";
                request = "launch";
                program.__raw = ''
                  function()
                    return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                  end
                '';
              }
            ];
            c = [
              {
                name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
                type = if isDarwin then "lldb" else "gdb";
                request = "launch";
                program.__raw = ''
                  function()
                    return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                  end
                '';
                cwd = "\${workspaceFolder}";
              }
            ];
            cpp = [
              {
                name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
                type = if isDarwin then "lldb" else "gdb";
                request = "launch";
                program.__raw = ''
                  function()
                    return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/', 'file')
                  end
                '';
                cwd = "\${workspaceFolder}";
              }
            ];
            rust = [
              {
                name = "Launch (${if isDarwin then "LLDB" else "GDB"})";
                type = if isDarwin then "lldb" else "gdb";
                request = "launch";
                program.__raw = ''
                  function()
                    return vim.fn.input('Path to file: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                  end
                '';
                cwd = "\${workspaceFolder}";
              }
            ];
            # Java configs are populated dynamically by jdtls.dap.setup_dap_main_class_configs()
            # when jdtls attaches — no static entries needed here.
          };
        };

        # ── Lazy loader (lz.n) ──────────────────────────────────────
        # Required for ANY `plugins.<x>.lazyLoad.settings.{cmd,ft,event,…}`
        # declaration to actually do anything. nixvim's `lazyLoad.*`
        # options serialize into a `lz.n`-shaped manifest and rely on
        # `lz.n` being present at startup to register the stub commands
        # / autocmds that trigger the real plugin load on first use.
        #
        # Without `plugins.lz-n.enable = true;` the lazy declarations
        # become silent no-ops: nixvim still pulls the plugin into the
        # pack-dir and skips its eager `setup()`, but never registers
        # the stub `:Neotree` / `:Yazi` / `:Oil` / `:DiffviewOpen` /
        # `:Trouble` commands either — so any keymap or function that
        # runs `vim.cmd("Neotree toggle")` (e.g. our
        # `dendritic_toggle_neotree_keep_focus`) fails with
        #   E492: Not an editor command: Neotree toggle
        # and the affected plugins are effectively dead.
        #
        # Telescope appears to work despite the same `lazyLoad.cmd`
        # declaration because something else (likely `noice.nvim` or
        # `todo-comments`) transitively `require`s it during init —
        # but that's incidental, not the lazy-load mechanism.
        plugins.lz-n.enable = true;

        # ── Telescope ───────────────────────────────────────────────
        plugins.telescope = {
          enable = true;
          lazyLoad.settings.cmd = "Telescope";
          extensions = {
            fzf-native.enable = true;
            ui-select.enable = true;
          };
          settings.defaults = {
            layout_strategy = "horizontal";
            sorting_strategy = "ascending";
            layout_config.prompt_position = "top";
          };
        };

        # ── File Browser (neo-tree) ─────────────────────────────────
        plugins.neo-tree = {
          enable = true;
          lazyLoad.settings.cmd = "Neotree";
          settings = {
            close_if_last_window = true;
            filesystem = {
              use_libuv_file_watcher = false;
              follow_current_file.enabled = true;
              hijack_netrw_behavior = "open_current";
              filtered_items.visible = true;
            };
            window.position = "left";
            window.width = 35;
          };
        };

        # ── Dashboard (startify) ─────────────────────────────────────
        plugins.startify = {
          enable = true;
          autoLoad = true;
          settings = {
            custom_header = [
              " ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗ "
              " ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║ "
              " ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║ "
              " ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║ "
              " ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║ "
              " ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ "
              "                                              "
              "           LLM-POWERED CODING ACTIVE          "
            ];
            session_autoload = false;
            update_oldfiles = false;
          };
        };

        # ── Yazi (terminal file manager integration) ───────────────
        plugins.yazi = {
          enable = true;
          lazyLoad.settings.cmd = "Yazi";
          settings = {
            open_for_directories = false; # Let Neo-tree handle directories for now
          };
        };

        # ── Oil (inline file editing) ───────────────────────────────
        plugins.oil = {
          enable = true;
          lazyLoad.settings.cmd = "Oil";
          settings = {
            default_file_explorer = false;
            delete_to_trash = true;
            view_options.show_hidden = true;
          };
        };

        # ── Git ─────────────────────────────────────────────────────
        plugins.gitsigns.enable = true;
        plugins.fugitive.enable = true;
        plugins.diffview = {
          enable = true;
          lazyLoad.settings.cmd = [
            "DiffviewOpen"
            "DiffviewClose"
            "DiffviewFileHistory"
          ];
        };

        # ── UI & Quality of Life ────────────────────────────────────
        plugins.lualine.enable = true;
        plugins.bufferline.enable = true;
        plugins.which-key.enable = true;
        plugins.nvim-autopairs.enable = true;
        plugins.indent-blankline.enable = true;
        plugins.todo-comments.enable = true;
        plugins.trouble = {
          enable = true;
          lazyLoad.settings.cmd = "Trouble";
        };
        plugins.noice.enable = true;
        plugins.notify.enable = true;
        plugins.web-devicons.enable = true;
        plugins.comment.enable = true;
        plugins.illuminate.enable = true;
        plugins.toggleterm.enable = true;
        plugins.mini = {
          enable = true;
          modules = {
            # base16 is setup manually in extraConfigLua
            surround = { };
            bufremove = { };
          };
        };

        # ── Better Markdown & Codeblocks (matches VSCode/Cursor) ─────
        plugins.render-markdown = {
          enable = true;
          lazyLoad.settings.ft = "markdown";
          settings = {
            code = {
              sign = false;
              width = "block";
              right_pad = 4;
              background.hl = "MarkdownCode";
            };
            heading = {
              sign = false;
              icons = [
                "󰲡 "
                "󰲣 "
                "󰲥 "
                "󰲧 "
                "󰲩 "
                "󰲫 "
              ];
            };
          };
        };

        # ── Agentic AI Coding (CodeCompanion) ───────────────────────
        extraPlugins = with pkgs.vimPlugins; [
          nvim-jdtls
          vim-autoswap # Automatically handle .swp file prompts
          nvim-colorizer-lua
          (pkgs.vimUtils.buildVimPlugin {
            pname = "codecompanion.nvim";
            version = "latest";
            src = pkgs.fetchFromGitHub {
              owner = "olimorris";
              repo = "codecompanion.nvim";
              rev = "fcfb7130f570ef2bbb52cbe9167c1999bc41029a";
              hash = "sha256-bcFT8PAFicRgPNAoxzrcAYH1wYJQ6Yu/E94H7M2DNaA=";
            };
            dependencies = [
              plenary-nvim
              nvim-treesitter
            ];
            doCheck = false;
          })
          (pkgs.vimUtils.buildVimPlugin {
            pname = "eagle.nvim";
            version = "latest";
            src = pkgs.fetchzip {
              url = "https://github.com/soulis-1256/eagle.nvim/archive/HEAD.tar.gz";
              sha256 = "1l131sv72mklizpa6yp8dbc52blcvcchmjmbbwm0y4bvl3rk9s0s";
            };
            doCheck = false;
          })
          pkgs.vimPlugins.typst-preview-nvim
        ];

        # ── Pre-setup hook: pre-load blink.cmp.fuzzy.rust ─────────────
        # Even after `modules/overlays.nix` patches the upstream throw
        # bug in `fuzzy/download/git.lua`, blink.cmp's first async
        # chain still queues "[blink.cmp] No fuzzy matching library
        # found!" onto `nvim_echo`'s UIEnter queue. That happens at
        # download/init.lua:27:
        #
        #   if version.current.missing and
        #      pcall(require, 'blink.cmp.fuzzy.rust') then return end
        #
        # During the chain context (running synchronously from inside
        # `blink-cmp.setup()` at init.lua line ~323), the `pcall(...)`
        # returns false for reasons specific to Nix's load-time
        # environment — by the time nvim is fully started and the
        # user opens a buffer, the very same `require` succeeds, but
        # by then the warning has already been queued and rendered
        # via `vim.api.nvim_echo` on the `UIEnter` event.
        #
        # Workaround: pre-load the rust module in `extraConfigLuaPre`,
        # which nixvim positions at the top of `init.lua` *before*
        # any plugin setup. If the require succeeds at that earlier
        # time, the result is cached in `package.loaded[...]`. Then
        # when blink.cmp's chain calls `pcall(require, ...)`, Lua's
        # require returns the cached module synchronously without
        # re-executing the chunk — pcall returns true, the early
        # return fires, no warning is queued.
        extraConfigLuaPre = ''
          -- Touch the rust module once up front so its dylib load,
          -- cpath append, and `blink_cmp_fuzzy` registration are
          -- all in `package.loaded[...]` by the time blink.cmp's
          -- setup chain checks. Wrapped in pcall so a genuine
          -- failure (missing dylib, wrong arch, etc.) doesn't
          -- crash init — blink will still fall back cleanly to the
          -- Lua matcher in that case.
          pcall(require, "blink.cmp.fuzzy.rust")
        '';

        extraConfigLua = ''
          -- ── Notification history + clipboard copy ──────────────────
          -- noice.nvim intercepts `vim.notify` and stores every
          -- notification (event = "notify") in its message manager.
          -- We tap that history directly via the public API instead
          -- of wrapping `vim.notify` ourselves — noice swaps the
          -- global wrapper during a deferred plugin-load step that
          -- happens AFTER `extraConfigLua` runs, so any wrapper we
          -- installed during init.lua would be silently bypassed.
          --
          -- API: `noice.message.manager.get(filter, opts)` →
          -- `NoiceMessage[]`. Each message responds to `:content()`
          -- (joined plain-text representation) and carries a `level`
          -- string ("info"/"warn"/"error"/...) plus a `ctime` epoch.
          local function dendritic_notify_history()
            local ok, manager = pcall(require, "noice.message.manager")
            if not ok then return {} end
            return manager.get({ event = "notify" }, { history = true, sort = true })
          end

          -- One-shot: copy the most recent notification to the system
          -- clipboard. Also writes to the unnamed register so `p`
          -- pastes inside Neovim.
          function _G.dendritic_yank_last_notification()
            local msgs = dendritic_notify_history()
            if #msgs == 0 then
              vim.notify("No notifications in history", vim.log.levels.WARN)
              return
            end
            local last = msgs[#msgs]
            local text = last:content()
            vim.fn.setreg("+", text)
            vim.fn.setreg('"', text)
            vim.notify("Copied last notification (" .. #text .. " chars)", vim.log.levels.INFO)
          end

          -- Browse: open a vim.ui.select picker over recent
          -- notifications (newest first). With telescope-ui-select
          -- enabled, this becomes a Telescope picker; confirming an
          -- entry copies that notification's full text to the
          -- system clipboard.
          function _G.dendritic_pick_notification_to_copy()
            local msgs = dendritic_notify_history()
            if #msgs == 0 then
              vim.notify("No notifications in history", vim.log.levels.WARN)
              return
            end
            local items = {}
            for i = #msgs, 1, -1 do
              table.insert(items, msgs[i])
            end
            vim.ui.select(items, {
              prompt = "Copy notification to clipboard:",
              format_item = function(m)
                local text = m:content() or ""
                local first_line = (text:match("[^\n]+") or text):gsub("%s+", " ")
                local lvl = tostring(m.level or "?"):upper()
                local ts = type(m.ctime) == "number" and os.date("%H:%M:%S", m.ctime) or "--:--:--"
                return "[" .. ts .. "] " .. lvl .. "  " .. first_line:sub(1, 100)
              end,
            }, function(choice)
              if not choice then return end
              local text = choice:content()
              vim.fn.setreg("+", text)
              vim.fn.setreg('"', text)
              vim.notify("Copied (" .. #text .. " chars)", vim.log.levels.INFO)
            end)
          end

          -- Use Neovim's bytecode loader for faster startup.
          if vim.loader then
            vim.loader.enable()

            -- Warm vim.loader's `rtp_cached` so cold lookups that
            -- happen inside a fast event (`vim.in_fast_event()`)
            -- find their modules. vim.loader's `get_rtp()` short-
            -- circuits in fast-event context (see
            -- `nvim/runtime/lua/vim/loader.lua` around line 93) and
            -- returns the cached rtp without ever scanning it —
            -- which means if the FIRST cache lookup occurs from a
            -- fast event, `rtp_cached` is still its initial `{}`,
            -- `find()` returns zero results, and Lua's standard
            -- searcher path (which doesn't know about Nvim plugin
            -- dirs) fails with the classic
            --   cache_loader: module 'X' not found
            --   no file '/nix/store/.../luajit2.1-.../share/lua/5.1/X.lua'
            -- error. We've hit this with `gitsigns.async` (loaded
            -- lazily inside a debounced autocmd that fires from a
            -- `:highlight` command issued by `mini.base16` during
            -- colorscheme apply — that's the fast event), and the
            -- failure mode would repeat for any plugin that defers
            -- a `require` into a fast event.
            --
            -- Forcing a single `vim.loader.find('vim')` call from
            -- this non-fast context populates `rtp_cached` once,
            -- after which subsequent fast-event lookups reuse the
            -- warm cache and resolve correctly. Pre-requiring the
            -- known offender `gitsigns.async` is a redundant
            -- belt-and-suspenders so its module table is also in
            -- `package.loaded` by the time the debounce fires —
            -- which short-circuits `require` before it even
            -- consults any searcher.
            pcall(vim.loader.find, 'vim')
            pcall(require, 'gitsigns.async')
          end

          -- ── Auto-open/close DAP UI on session start/end (VSCode-like) ──
          vim.schedule(function()
            local ok_dap, dap = pcall(require, "dap")
            local ok_dapui, dapui = pcall(require, "dapui")
            if not (ok_dap and ok_dapui) then
              return
            end
            dapui.setup()
            dap.listeners.before.attach.dapui_config = function() dapui.open() end
            dap.listeners.before.launch.dapui_config = function() dapui.open() end
            dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
            dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
          end)

          -- Enable mouse hover events for eagle.nvim
          vim.o.mousemoveevent = true

          -- Hot-reload Neovim config when init.lua changes on disk.
          -- This catches external updates (e.g. Home Manager switches) without
          -- requiring a Neovim restart.
          if not vim.g.dendritic_hot_reload_initialized then
            vim.g.dendritic_hot_reload_initialized = true
            local init_file = vim.fn.stdpath("config") .. "/init.lua"
            local palette_file = vim.fn.expand("~/colors.toml")
            local init_poll = (vim.uv and vim.uv.new_fs_poll) and vim.uv.new_fs_poll() or nil
            local palette_poll = (vim.uv and vim.uv.new_fs_poll) and vim.uv.new_fs_poll() or nil
            local uv = vim.uv or vim.loop
            local last_palette_mtime = nil
            local file_mtime_by_buf = {}

            local function reload_init()
              local ok, source_err = pcall(vim.cmd, "silent source " .. vim.fn.fnameescape(init_file))
              if type(_G.dendritic_reload_theme) == "function" then
                pcall(_G.dendritic_reload_theme)
              end
              if ok then
                vim.notify("Neovim config reloaded", vim.log.levels.INFO)
              else
                vim.notify("Neovim config reload failed: " .. tostring(source_err), vim.log.levels.ERROR)
              end
            end

            local function palette_mtime_key()
              if not uv or type(uv.fs_stat) ~= "function" then
                return nil
              end
              local stat = uv.fs_stat(palette_file)
              if not stat or not stat.mtime then
                return nil
              end
              return tostring(stat.mtime.sec or 0) .. ":" .. tostring(stat.mtime.nsec or 0)
            end

            local function file_mtime_key(path)
              if not uv or type(uv.fs_stat) ~= "function" then
                return nil
              end
              local stat = uv.fs_stat(path)
              if not stat or not stat.mtime then
                return nil
              end
              return tostring(stat.mtime.sec or 0) .. ":" .. tostring(stat.mtime.nsec or 0)
            end

            local function reload_theme_only(notify)
              if type(_G.dendritic_reload_theme) == "function" then
                local ok, reload_err = pcall(_G.dendritic_reload_theme)
                if ok and notify then
                  vim.notify("Neovim theme reloaded", vim.log.levels.INFO)
                elseif not ok then
                  vim.notify("Neovim theme reload failed: " .. tostring(reload_err), vim.log.levels.ERROR)
                end
              end
            end

            local function track_or_reload_current_file()
              if vim.fn.mode() == "c" then
                return
              end
              local bufnr = vim.api.nvim_get_current_buf()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end
              if vim.bo[bufnr].buftype ~= "" then
                return
              end
              local path = vim.api.nvim_buf_get_name(bufnr)
              if path == "" or vim.fn.filereadable(path) ~= 1 then
                return
              end
              local current_mtime = file_mtime_key(path)
              if not current_mtime then
                return
              end
              local known_mtime = file_mtime_by_buf[bufnr]
              if not known_mtime then
                file_mtime_by_buf[bufnr] = current_mtime
                return
              end
              if current_mtime ~= known_mtime then
                file_mtime_by_buf[bufnr] = current_mtime
                vim.cmd("silent! checktime")
              end
            end

            if init_poll then
              init_poll:start(init_file, 1000, vim.schedule_wrap(function(err, prev, cur)
                if err or not prev or not cur then
                  return
                end
                if prev.mtime.sec == cur.mtime.sec and prev.mtime.nsec == cur.mtime.nsec then
                  return
                end
                reload_init()
              end))
            end

            if palette_poll and vim.fn.filereadable(palette_file) == 1 then
              last_palette_mtime = palette_mtime_key()
              palette_poll:start(palette_file, 500, vim.schedule_wrap(function(err, prev, cur)
                if err or not prev or not cur then
                  return
                end
                if prev.mtime.sec == cur.mtime.sec and prev.mtime.nsec == cur.mtime.nsec then
                  return
                end
                last_palette_mtime = palette_mtime_key()
                reload_theme_only(true)
              end))
            end

            -- Home Manager switches can swap the colors.toml symlink in a way fs_poll
            -- misses; this focus check catches it and keeps live sessions in sync.
            vim.api.nvim_create_autocmd({ "FocusGained", "VimResume", "BufEnter" }, {
              callback = function()
                if vim.fn.filereadable(palette_file) ~= 1 then
                  return
                end
                local current_mtime = palette_mtime_key()
                if not current_mtime then
                  return
                end
                if not last_palette_mtime then
                  last_palette_mtime = current_mtime
                  return
                end
                if current_mtime ~= last_palette_mtime then
                  last_palette_mtime = current_mtime
                  reload_theme_only(true)
                end
              end,
            })

            vim.api.nvim_create_autocmd({
              "FocusGained",
              "VimResume",
              "BufEnter",
              "WinEnter",
              "CursorHold",
              "CursorHoldI",
              "TermLeave",
              "TermClose",
            }, {
              callback = track_or_reload_current_file,
            })

            vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
              callback = function(ev)
                file_mtime_by_buf[ev.buf] = nil
              end,
            })

            if init_poll or palette_poll then
              vim.api.nvim_create_autocmd("VimLeavePre", {
                callback = function()
                  pcall(function()
                    if init_poll then
                      init_poll:stop()
                      init_poll:close()
                    end
                    if palette_poll then
                      palette_poll:stop()
                      palette_poll:close()
                    end
                  end)
                end,
              })
            end
          end

          vim.schedule(function()
            -- Setup eagle.nvim for VSCode-like mouse hover.
            local ok_eagle, eagle = pcall(require, "eagle")
            if ok_eagle then
              eagle.setup()
            end

            -- CodeCompanion setup.
            --
            -- Adapter overrides must live under `adapters.http.<name>`
            -- (or `adapters.acp.<name>`), NOT at the top level. The
            -- resolver in `codecompanion/adapters/http/init.lua` looks
            -- up `config.adapters.http[name]`; anything dropped at
            -- `config.adapters.openai` is silently ignored and the
            -- upstream default — whose `env.api_key = "OPENAI_API_KEY"`
            -- is the env-var NAME, expected to be resolved via
            -- `os.getenv` — gets used. Without the override the literal
            -- string "OPENAI_API_KEY" ends up in the `Authorization:
            -- Bearer ''${api_key}` header (because `os.getenv` returns
            -- nil when we deliberately keep that env var unset), which
            -- OpenAI rejects with `invalid_api_key: OPENAI_A**_KEY`.
            --
            -- With the override at `adapters.http.openai`, codecompanion's
            -- `utils/adapters.lua` sees the `cmd:` prefix on `api_key`,
            -- runs `cat <sops-path>` once per request via `vim.system`,
            -- and uses stdout as the bearer token — no env-var leaks,
            -- no plaintext key in the Nix store.
            local ok, cc = pcall(require, "codecompanion")
            if ok then
              cc.setup({
                adapters = {
                  http = {
                    openai = function()
                      return require("codecompanion.adapters").extend("openai", {
                        env = {
                          api_key = "cmd:cat ${config.sops.secrets.openai_api_key.path}",
                        },
                      })
                    end,
                  },
                },
                strategies = {
                  chat = { adapter = "openai" },
                  inline = { adapter = "openai" },
                  agent = { adapter = "openai" },
                },
              })
            end
          end)

          -- Universal clipboard provider for local + SSH workflows.
          local function has(bin)
            return vim.fn.executable(bin) == 1
          end
          local function setup_universal_clipboard()
            local is_ssh = (vim.env.SSH_TTY ~= nil) or (vim.env.SSH_CONNECTION ~= nil) or (vim.env.SSH_CLIENT ~= nil)
            if is_ssh then
              vim.g.clipboard = "osc52"
              return
            end
            if has("pbcopy") and has("pbpaste") then
              vim.g.clipboard = {
                name = "pbcopy",
                copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
                paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
                cache_enabled = 1,
              }
              return
            end
            if has("wl-copy") and has("wl-paste") then
              vim.g.clipboard = {
                name = "wl-clipboard",
                copy = { ["+"] = "wl-copy --foreground --type text/plain", ["*"] = "wl-copy --foreground --primary --type text/plain" },
                paste = { ["+"] = "wl-paste --no-newline", ["*"] = "wl-paste --no-newline --primary" },
                cache_enabled = 1,
              }
              return
            end
            if has("xclip") then
              vim.g.clipboard = {
                name = "xclip",
                copy = { ["+"] = "xclip -selection clipboard", ["*"] = "xclip -selection primary" },
                paste = { ["+"] = "xclip -selection clipboard -o", ["*"] = "xclip -selection primary -o" },
                cache_enabled = 1,
              }
              return
            end
            if has("xsel") then
              vim.g.clipboard = {
                name = "xsel",
                copy = { ["+"] = "xsel --clipboard --input", ["*"] = "xsel --primary --input" },
                paste = { ["+"] = "xsel --clipboard --output", ["*"] = "xsel --primary --output" },
                cache_enabled = 1,
              }
              return
            end
            vim.g.clipboard = "osc52"
          end
          setup_universal_clipboard()

          -- Keep Neo-tree out of regular tab buffers.
          local ok_bufferline, bufferline = pcall(require, "bufferline")
          if ok_bufferline then
            bufferline.setup({
              options = {
                custom_filter = function(bufnr)
                  return vim.bo[bufnr].filetype ~= "neo-tree"
                end,
                offsets = {
                  {
                    filetype = "neo-tree",
                    text = "Explorer",
                    highlight = "Directory",
                    separator = true,
                  },
                },
              },
            })
          end

          _G.dendritic_toggle_neotree_keep_focus = function()
            local prev_win = vim.api.nvim_get_current_win()
            vim.cmd("Neotree toggle")
            if vim.bo.filetype == "neo-tree" and vim.api.nvim_win_is_valid(prev_win) then
              vim.api.nvim_set_current_win(prev_win)
            end
          end

          -- ── VS Code / Cursor 1:1 Aesthetic Refinements ────────────────

          -- Tab / gutter / Neo-tree parity with Stylix
          local fallback_palette = {
            base00 = "${config.lib.stylix.colors.withHashtag.base00}",
            base01 = "${config.lib.stylix.colors.withHashtag.base01}",
            base02 = "${config.lib.stylix.colors.withHashtag.base02}",
            base03 = "${config.lib.stylix.colors.withHashtag.base03}",
            base04 = "${config.lib.stylix.colors.withHashtag.base04}",
            base05 = "${config.lib.stylix.colors.withHashtag.base05}",
            base06 = "${config.lib.stylix.colors.withHashtag.base06}",
            base07 = "${config.lib.stylix.colors.withHashtag.base07}",
            base08 = "${config.lib.stylix.colors.withHashtag.base08}",
            base09 = "${config.lib.stylix.colors.withHashtag.base09}",
            base0A = "${config.lib.stylix.colors.withHashtag.base0A}",
            base0B = "${config.lib.stylix.colors.withHashtag.base0B}",
            base0C = "${config.lib.stylix.colors.withHashtag.base0C}",
            base0D = "${config.lib.stylix.colors.withHashtag.base0D}",
            base0E = "${config.lib.stylix.colors.withHashtag.base0E}",
            base0F = "${config.lib.stylix.colors.withHashtag.base0F}",
          }
          local active_palette = vim.deepcopy(fallback_palette)
          local function color(name)
            return active_palette[name] or fallback_palette[name]
          end

          local function apply_style_overrides()
            -- Enable Cursive Italics for logic flow (matches premium themes)
            vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = color("base03") })
            vim.api.nvim_set_hl(0, "Keyword", { italic = true })
            vim.api.nvim_set_hl(0, "Conditional", { italic = true })
            vim.api.nvim_set_hl(0, "Repeat", { italic = true })
            vim.api.nvim_set_hl(0, "Function", { italic = true, bold = true })
            vim.api.nvim_set_hl(0, "Operator", { fg = color("base05") }) -- Muted operators

            -- High-Fidelity Treesitter / LSP Semantic Token Overrides
            -- This makes the syntax tree "pop" like VS Code's TextMate scopes
            vim.api.nvim_set_hl(0, "@variable", { fg = color("base05") })
            vim.api.nvim_set_hl(0, "@variable.member", { fg = color("base08") }) -- Fields/Members
            vim.api.nvim_set_hl(0, "@property", { fg = color("base08") })
            vim.api.nvim_set_hl(0, "@parameter", { fg = color("base09"), italic = true }) -- Parameters in italics
            vim.api.nvim_set_hl(0, "@constructor", { fg = color("base0D"), bold = true })

            -- Nix Specific Highlighting Refinements
            vim.api.nvim_set_hl(0, "@variable.nix", { fg = color("base05") })
            vim.api.nvim_set_hl(0, "@function.call.nix", { fg = color("base0D") })

            -- Clean up UI elements to match VS Code's "Flat" look
            vim.api.nvim_set_hl(0, "LineNr", { fg = color("base02") })
            vim.api.nvim_set_hl(0, "CursorLineNr", { fg = color("base04"), bold = true })
            vim.api.nvim_set_hl(0, "VertSplit", { fg = color("base01"), bg = "NONE" })
            vim.api.nvim_set_hl(0, "WinSeparator", { fg = color("base01"), bg = "NONE" })

            -- Match VSCode CodeBlock backgrounds
            vim.api.nvim_set_hl(0, "MarkdownCode", { bg = color("base01") })
            vim.api.nvim_set_hl(0, "MarkdownCodeBlock", { bg = color("base01") })
          end

          local function apply_stylix_highlights()
            local base00 = color("base00")
            local base01 = color("base01")
            local base02 = color("base02")
            local base03 = color("base03")
            local base05 = color("base05")
            local base0D = color("base0D")

            -- Gutter must stay base00
            vim.api.nvim_set_hl(0, "SignColumn", { bg = base00 })
            vim.api.nvim_set_hl(0, "SignColumnSB", { bg = base00 })
            vim.api.nvim_set_hl(0, "FoldColumn", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "LineNr", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "LineNrAbove", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "LineNrBelow", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "CursorLineNr", { bg = base00, fg = base05, bold = true })
            vim.api.nvim_set_hl(0, "CursorLineFold", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "CursorLineSign", { bg = base00, fg = base03 })

            -- Neo-tree sidebar/gutter
            vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = base01, fg = base05 })
            vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = base01, fg = base05 })
            vim.api.nvim_set_hl(0, "NeoTreeSignColumn", { bg = base00, fg = base05 })
            vim.api.nvim_set_hl(0, "NeoTreeLineNr", { bg = base00, fg = base03 })
            vim.api.nvim_set_hl(0, "NeoTreeCursorLineNr", { bg = base00, fg = base05, bold = true })
            vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = base01, fg = base01 })
            vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = base01, fg = base03 })

            -- Tabs: inactive=base01, active=base02
            vim.api.nvim_set_hl(0, "BufferLineFill", { bg = base00 })
            vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = base01, fg = base03 })
            vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = base01, fg = base05 })
            vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = base02, fg = base05, bold = true })
            vim.api.nvim_set_hl(0, "BufferLineSeparator", { bg = base00, fg = base00 })
            vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { bg = base00, fg = base00 })
            vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { bg = base00, fg = base00 })
            vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { bg = base02, fg = base0D })
            vim.api.nvim_set_hl(0, "TabLine", { bg = base01, fg = base03 })
            vim.api.nvim_set_hl(0, "TabLineSel", { bg = base02, fg = base05, bold = true })

            -- Ensure filetype icon chips inherit the right tab backgrounds.
            for _, group in ipairs(vim.fn.getcompletion("BufferLineDevIcon", "highlight")) do
              local current = vim.api.nvim_get_hl(0, { name = group, link = false })
              local fg = current.fg and string.format("#%06x", current.fg) or base05
              local bg = group:match("Selected$") and base02 or base01
              vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
            end
          end

          local function parse_palette_from_colors_toml(path)
            local file = io.open(path, "r")
            if not file then
              return nil
            end
            local palette = {}
            local in_palette = false
            for line in file:lines() do
              local section = line:match("^%s*%[([^%]]+)%]%s*$")
              if section then
                in_palette = (section == "palette")
              elseif in_palette then
                local key, value = line:match('^%s*(base[%x][%x])%s*=%s*"(#?[%x]+)"%s*$')
                if key and value then
                  palette[key] = value:sub(1, 1) == "#" and value or ("#" .. value)
                end
              end
            end
            file:close()
            for key in pairs(fallback_palette) do
              if not palette[key] then
                return nil
              end
            end
            return palette
          end

          _G.dendritic_reload_theme = function()
            local ok2, base16 = pcall(require, "mini.base16")
            if not ok2 then
              return
            end
            local palette_path = vim.fn.expand("~/colors.toml")
            active_palette = parse_palette_from_colors_toml(palette_path) or fallback_palette
            base16.setup({ palette = active_palette })
            apply_style_overrides()
            apply_stylix_highlights()
          end

          _G.dendritic_reload_theme()
          vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "BufEnter", "WinEnter" }, {
            callback = function()
              apply_style_overrides()
              apply_stylix_highlights()
            end,
          })

          -- Neo-tree should not allow horizontal scrolling.
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "neo-tree",
            callback = function(ev)
              local b = ev.buf
              local function apply_no_hscroll()
                for _, w in ipairs(vim.fn.win_findbuf(b)) do
                  pcall(vim.api.nvim_set_option_value, "wrap", true, { win = w })
                  pcall(vim.api.nvim_set_option_value, "linebreak", true, { win = w })
                end
              end
              local mapopts = { buffer = b, silent = true, noremap = true, nowait = true }
              for _, lhs in ipairs({
                "zh", "zl", "zH", "zL",
                "<Left>", "<Right>", "<S-Left>", "<S-Right>",
                "<ScrollWheelLeft>", "<ScrollWheelRight>",
                "<S-ScrollWheelLeft>", "<S-ScrollWheelRight>",
                "<2-ScrollWheelLeft>", "<2-ScrollWheelRight>",
              }) do
                vim.keymap.set({ "n", "x", "i" }, lhs, "<Nop>", mapopts)
              end
              local function clamp_leftcol()
                if vim.bo[b].filetype ~= "neo-tree" then
                  return
                end
                for _, w in ipairs(vim.fn.win_findbuf(b)) do
                  if vim.api.nvim_win_is_valid(w) then
                    local view = vim.api.nvim_win_call(w, vim.fn.winsaveview)
                    if view.leftcol ~= 0 then
                      view.leftcol = 0
                      pcall(vim.api.nvim_win_call, w, function()
                        vim.fn.winrestview(view)
                      end)
                    end
                  end
                end
              end
              vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved", "BufEnter", "WinEnter" }, {
                buffer = b,
                callback = function()
                  apply_no_hscroll()
                  clamp_leftcol()
                end,
              })
              apply_no_hscroll()
              clamp_leftcol()
            end,
          })

          -- Highlight color literals in source files.
          vim.schedule(function()
            local colorizer_ok, colorizer = pcall(require, "colorizer")
            if colorizer_ok then
              colorizer.setup({
                "*",
                css = { css = true, css_fn = true, mode = "background" },
              })
            end
          end)

          -- Fancy DAP Breakpoint Icons
          vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
          vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "DiagnosticWarn" })

          -- ── Modern Textutil Integration (RTF/DOC Editing) ─────────────
          -- Transparently edit RTF, DOC, and WordML files as plain text
          local rtf_group = vim.api.nvim_create_augroup("Textutil", { clear = true })

          vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
            group = rtf_group,
            pattern = { "*.rtf", "*.doc", "*.docx", "*.wordml" },
            callback = function(ev)
              local file = ev.file
              local cmd = string.format("textutil -convert txt -stdout %q", file)
              local output = vim.fn.systemlist(cmd)
              vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
              vim.api.nvim_set_option_value("modified", false, { buf = 0 })
              vim.api.nvim_set_option_value("filetype", "text", { buf = 0 })
            end,
          })

          vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
            group = rtf_group,
            pattern = { "*.rtf", "*.doc", "*.docx", "*.wordml" },
            callback = function(ev)
              local file = ev.file
              local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
              local format = file:match("%.(%w+)$")
              -- Map extensions to textutil formats
              if format == "docx" or format == "doc" then format = "wordml" end
              
              local cmd = string.format("textutil -convert %s -stdin -output %q", format, file)
              vim.fn.system(cmd, content)
              vim.api.nvim_set_option_value("modified", false, { buf = 0 })
              vim.notify("Saved as " .. format, vim.log.levels.INFO)
            end,
          })
        '';

        # ── Keymaps ─────────────────────────────────────────────────
        keymaps = [
          # File browser
          {
            mode = "n";
            key = "<leader>e";
            action = "<cmd>lua dendritic_toggle_neotree_keep_focus()<cr>";
            options.desc = "Toggle Neo-tree";
          }
          {
            mode = "n";
            key = "-";
            action = "<cmd>Oil<cr>";
            options.desc = "Open Oil";
          }

          # Telescope
          {
            mode = "n";
            key = "<leader>sf";
            action = "<cmd>Telescope find_files<cr>";
            options.desc = "Find Files";
          }
          {
            mode = "n";
            key = "<leader>sg";
            action = "<cmd>Telescope live_grep<cr>";
            options.desc = "Live Grep";
          }
          {
            mode = "n";
            key = "<leader>sb";
            action = "<cmd>Telescope buffers<cr>";
            options.desc = "Buffers";
          }
          {
            mode = "n";
            key = "<leader>sh";
            action = "<cmd>Telescope help_tags<cr>";
            options.desc = "Help Tags";
          }
          {
            mode = "n";
            key = "<leader>sr";
            action = "<cmd>Telescope oldfiles<cr>";
            options.desc = "Recent Files";
          }
          {
            mode = "n";
            key = "<leader>sd";
            action = "<cmd>Telescope diagnostics<cr>";
            options.desc = "Diagnostics";
          }
          {
            mode = "n";
            key = "<leader>ss";
            action = "<cmd>Telescope lsp_document_symbols<cr>";
            options.desc = "Document Symbols";
          }
          {
            mode = "n";
            key = "<leader>sn";
            action = "<cmd>lua dendritic_pick_notification_to_copy()<cr>";
            options.desc = "Search Notifications (copy on select)";
          }
          {
            mode = "n";
            key = "<leader>yn";
            action = "<cmd>lua dendritic_yank_last_notification()<cr>";
            options.desc = "Yank last notification to clipboard";
          }

          # LSP
          {
            mode = "n";
            key = "gd";
            action = "<cmd>Telescope lsp_definitions<cr>";
            options.desc = "Go to Definition";
          }
          {
            mode = "n";
            key = "gr";
            action = "<cmd>Telescope lsp_references<cr>";
            options.desc = "References";
          }
          {
            mode = "n";
            key = "gi";
            action = "<cmd>Telescope lsp_implementations<cr>";
            options.desc = "Implementations";
          }
          {
            mode = "n";
            key = "K";
            action.__raw = "vim.lsp.buf.hover";
            options.desc = "Hover";
          }
          {
            mode = "n";
            key = "<leader>ca";
            action.__raw = "vim.lsp.buf.code_action";
            options.desc = "Code Action";
          }
          {
            mode = "n";
            key = "<leader>cr";
            action.__raw = "vim.lsp.buf.rename";
            options.desc = "Rename Symbol";
          }

          # Diagnostics
          {
            mode = "n";
            key = "<leader>xx";
            action = "<cmd>Trouble diagnostics toggle<cr>";
            options.desc = "Diagnostics (Trouble)";
          }
          {
            mode = "n";
            key = "[d";
            action.__raw = "vim.diagnostic.goto_prev";
            options.desc = "Prev Diagnostic";
          }
          {
            mode = "n";
            key = "]d";
            action.__raw = "vim.diagnostic.goto_next";
            options.desc = "Next Diagnostic";
          }

          # DAP (Debug)
          {
            mode = "n";
            key = "<leader>db";
            action.__raw = "require('dap').toggle_breakpoint";
            options.desc = "Toggle Breakpoint";
          }
          {
            mode = "n";
            key = "<leader>dc";
            action.__raw = "require('dap').continue";
            options.desc = "Continue";
          }
          {
            mode = "n";
            key = "<leader>di";
            action.__raw = "require('dap').step_into";
            options.desc = "Step Into";
          }
          {
            mode = "n";
            key = "<leader>do";
            action.__raw = "require('dap').step_over";
            options.desc = "Step Over";
          }
          {
            mode = "n";
            key = "<leader>dO";
            action.__raw = "require('dap').step_out";
            options.desc = "Step Out";
          }
          {
            mode = "n";
            key = "<leader>du";
            # Wrapped in `function() ... end` so the require resolves at
            # keypress time, not at keymap-registration time. Keeps the
            # keymap intact even if dap-ui's lazyLoad is reintroduced.
            action.__raw = "function() require('dapui').toggle() end";
            options.desc = "Toggle DAP UI";
          }
          {
            mode = "n";
            key = "<leader>dr";
            action.__raw = "require('dap').repl.open";
            options.desc = "Open REPL";
          }

          # Git
          {
            mode = "n";
            key = "<leader>gg";
            action = "<cmd>Git<cr>";
            options.desc = "Git Status (Fugitive)";
          }
          {
            mode = "n";
            key = "<leader>gd";
            action = "<cmd>DiffviewOpen<cr>";
            options.desc = "Diff View";
          }

          # Terminal
          {
            mode = "n";
            key = "<leader>t";
            action = "<cmd>ToggleTerm<cr>";
            options.desc = "Toggle Terminal";
          }

          # Text Wrapping
          {
            mode = "n";
            key = "<leader>wh";
            action = "<cmd>set textwidth=80 formatoptions+=t<cr>mzgggqG`z";
            options.desc = "Hard wrap entire buffer at 80 cols";
          }
          {
            mode = "v";
            key = "<leader>wh";
            action = "<cmd>set textwidth=80 formatoptions+=t<cr>gq";
            options.desc = "Hard wrap selection at 80 cols";
          }
          {
            mode = "n";
            key = "<leader>ws";
            action.__raw = ''
              function()
                if vim.wo.wrap then
                  vim.wo.wrap = false
                  vim.wo.linebreak = false
                  vim.wo.colorcolumn = ""
                else
                  vim.wo.wrap = true
                  vim.wo.linebreak = true
                  vim.wo.colorcolumn = "80"
                end
              end
            '';
            options.desc = "Toggle soft wrap at 80 cols";
          }
          {
            mode = "v";
            key = "<leader>ws";
            action.__raw = ''
              function()
                if vim.wo.wrap then
                  vim.wo.wrap = false
                  vim.wo.linebreak = false
                  vim.wo.colorcolumn = ""
                else
                  vim.wo.wrap = true
                  vim.wo.linebreak = true
                  vim.wo.colorcolumn = "80"
                end
              end
            '';
            options.desc = "Toggle soft wrap at 80 cols";
          }

          # AI / Agentic
          {
            mode = "n";
            key = "<leader>ac";
            action = "<cmd>CodeCompanionChat<cr>";
            options.desc = "AI Chat";
          }
          {
            mode = "v";
            key = "<leader>ac";
            action = "<cmd>CodeCompanionChat<cr>";
            options.desc = "AI Chat (selection)";
          }
          {
            mode = "n";
            key = "<leader>ai";
            action = "<cmd>CodeCompanion<cr>";
            options.desc = "AI Inline";
          }
          # Minuet (inline OpenAI completion) toggles. `Minuet
          # virtualtext` toggles auto ghost-text; `Minuet blink
          # toggle` toggles whether minuet auto-fires inside blink's
          # menu. Manual fire is always available via `<A-y>` in
          # insert mode (bound in plugins.blink-cmp.settings.keymap).
          {
            mode = "n";
            key = "<leader>av";
            action = "<cmd>Minuet virtualtext toggle<cr>";
            options.desc = "AI Virtualtext (Minuet) toggle";
          }
          {
            mode = "n";
            key = "<leader>ab";
            action = "<cmd>Minuet blink toggle<cr>";
            options.desc = "AI in blink menu (Minuet) toggle";
          }

          # Yazi
          {
            mode = "n";
            key = "<leader>y";
            action = "<cmd>Yazi<cr>";
            options.desc = "Open Yazi";
          }

          # Buffers
          {
            mode = "n";
            key = "<leader>bd";
            action.__raw = "require('mini.bufremove').delete";
            options.desc = "Delete Buffer";
          }
          {
            mode = "n";
            key = "<S-h>";
            action = "<cmd>bprevious<cr>";
            options.desc = "Prev Buffer";
          }
          {
            mode = "n";
            key = "<S-l>";
            action = "<cmd>bnext<cr>";
            options.desc = "Next Buffer";
          }

          # Window navigation
          {
            mode = "n";
            key = "<C-h>";
            action = "<C-w>h";
            options.desc = "Move Left";
          }
          {
            mode = "n";
            key = "<C-j>";
            action = "<C-w>j";
            options.desc = "Move Down";
          }
          {
            mode = "n";
            key = "<C-k>";
            action = "<C-w>k";
            options.desc = "Move Up";
          }
          {
            mode = "n";
            key = "<C-l>";
            action = "<C-w>l";
            options.desc = "Move Right";
          }

          # Format (project-local treefmt multiplexer)
          {
            mode = "n";
            key = "<leader>f";
            action = "<cmd>silent !treefmt<cr><cmd>edit<cr>";
            options.desc = "Run treefmt (project)";
          }
          # MicroVM
          {
            mode = "n";
            key = "<leader>vm";
            action = "<cmd>TermExec cmd='microvm-run'<cr>";
            options.desc = "Launch MicroVM";
          }
        ];
      };

      # ── Formatter & Linter packages ─────────────────────────────
      home.packages =
        with pkgs;
        [
          treefmt # Project formatter multiplexer
          typst # Typst compiler
          tinymist # Typst LSP
          ruff # Python linting
          # Linters
          statix # Nix
          shellcheck # Shell
          eslint_d # JS/TS
          asmfmt # Assembly formatter
          asm-lsp # Assembly LSP (ARM support)
          # VSCode Extensions (available in PATH/store)
          vscode-extensions.bbenoist.nix
          vscode-extensions.jnoortheen.nix-ide
        ]
        ++ lib.optionals isDarwin [
          swiftformat # Swift
          swiftlint # Swift
          sourcekit-lsp # Swift LSP
        ]
        ++ lib.optionals (!isDarwin) [
          gdb # Debugger (Linux)
          xclip
          xsel
          wl-clipboard
        ];

      # ── Fancy-cat Configuration ──────────────────────────────────
    };
}
