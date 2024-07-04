{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

# my universal neovim configuration with Nix Syntax using NixVim!
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];
  nixpkgs.config.allowUnsupportedSystemPredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "swiftformat"
      "sourcekit-lsp"
    ];

  # nixvim specific dependencies
  home.packages = with pkgs; [ ];

  programs.nixvim =
    let
      toLua = str: ''
        lua << EOF
        ${str}
        EOF
      '';
      toLuaFile = file: ''
        lua << EOF
        ${builtins.readFile file}
        EOF
      '';
    in
    {
      enable = true;
      enableMan = true; # enable man pages for nixvim options.
      opts = {
        number = true; # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 4; # Tab width should be 4
        termguicolors = true;
      };
      extraConfigLua = ''
        -- Print a little welcome message when nvim is opened!
        -- print("Hello world!")

        -- All my configuration options for nvim:
        ${builtins.readFile ./options.lua}
      '';
      #globals.mapleader = ","; # Sets the leader key to comma
      keymaps = [
        # https://github.com/nix-community/nixvim/tree/main#key-mappings
      ];
      plugins = {
        #JAVALSP
        nvim-jdtls = {
          enable = true;
          data = "${config.xdg.cacheHome}/jdtls/workspace";
          configuration = "${config.xdg.cacheHome}/jdtls/config";
          initOptions = null;
          rootDir = {
            __raw = "require('jdtls.setup').find_root({'.git','mvnw','gradlew'})";
          };
          settings = null;
          cmd = [
            "${pkgs.jdt-language-server}/bin/jdtls"
            #"-foo" "bar"
          ];
        };
        clangd-extensions.enable = true;
        lsp-format.enable = true;
        none-ls = {
          enable = true;
          enableLspFormat = true;
          sources = {
            formatting = {
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
              #trace: warning: alex profile: [DEV] Nixvim (plugins.none-ls): Some tools are declared locally but are not in the upstream list of supported plugins.
              #-> [opentofu_fmt, typstyle, xmllint]
              # typstyle.enable = false;
              # opentofu_fmt.enable = false;
              # xmllint.enable = false;
            };
          };
          notifyFormat = "[null-ls] %s";
        };
        efmls-configs = {
          enable = true;
          setup = {
            all = {
              #formatter = [
              #  "languagetool"
              #];
              linter = [ "codespell" ];
            };
            nix = {
              formatter = [ "nixfmt" ];
              linter = [ "statix" ];
            };
            java = {
              /*
                My favorite combination is:
                google-java-format for auto-formatting (prevent bikeshedding about indentation and the like)
                checkstyle with google-java-format rules
                errorprone (prevent common, careless mistakes)
                NullAway (prevent NullPointerExceptions)
                infer (optionally) to be really safe :)
                In my opinion, linters should be executable via the command-line. Hence i don't like SonarQube and sonalint.
              */
              formatter = [ "google_java_format" ];
              #linter =   [ "" ]; 
            };
            python = {
              formatter = [ "black" ];
              linter = [ "flake8" ];
            };
            markdown = {
              formatter = [ "mdformat" ];
              #linter =   [];
            };
            lua = {
              formatter = [ "lua_format" ];
              #linter =   [];
            };
            bash = {
              formatter = [ "beautysh" ];
              linter = [ "bashate" ];
            };
          };
          toolPackages.nixfmt = pkgs.nixfmt-rfc-style;
        };
        notify = {
          enable = true;
          #stages = "slide";
        };
        gitsigns.enable = true;
        lsp = {
          enable = true;
          servers = {
            # https://nix-community.github.io/nixvim/plugins/lsp/
            ansiblels = {
              enable = false;
              package = null;
            };
            astro = {
              enable = false;
              package = null;
            };
            bashls = {
              enable = false;
              package = ./derivations-for-nixvim/bash-language-server;
            };
            beancount = {
              enable = false;
              package = null;
            };
            biome = {
              enable = false;
              package = null;
            };
            ccls = {
              # C/C++/Objective-C language server
              enable = true;
              package = null; # set to pkgs.packagename
            };
            clangd = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            clojure-lsp = {
              enable = false;
              package = null;
            };
            cmake = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            csharp-ls = {
              enable = false;
              package = null; # NOT AVAILABLE on DARWIN
            };
            cssls = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            dagger = {
              enable = false;
              package = null;
            };
            dartls = {
              enable = false;
              package = null;
            };
            denols = {
              enable = false;
              package = null;
            };
            dhall-lsp-server = {
              enable = false;
              package = null;
            };
            digestif = {
              enable = false;
              package = null;
            };
            dockerls = {
              enable = false;
              package = null;
            };
            efm = {
              enable = true;
              package = null;
            };
            elixirls = {
              enable = false;
              package = null;
            };
            elmls = {
              enable = false;
              package = null;
            };
            emmet-ls = {
              enable = false;
              package = null;
            };
            eslint = {
              enable = false;
              package = null;
            };
            fsautocomplete = {
              enable = false;
              package = null; # DOESN'T COMPILE ON DARWIN
            };
            futhark-lsp = {
              enable = false;
              package = null;
            };
            gdscript = {
              enable = false;
              package = null;
            };
            gleam = {
              enable = false;
              package = null;
            };
            gopls = {
              enable = false;
              package = null;
            };
            graphql = {
              enable = false;
              package = null;
            };
            hls = {
              enable = false;
              package = null;
            };
            html = {
              enable = false;
              package = null;
            };
            htmx = {
              enable = false;
              #  plugins.lsp.servers.htmx.package = ./htmx-lsp-derivation.nix;
              package = null; # FAILED
            };
            intelephense = {
              enable = false;
              package = null;
            };
            java-language-server = {
              # USING JDTLS instead!
              enable = false;
              package = null;
            };
            jsonls = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            julials = {
              enable = false;
              package = null;
            };
            kotlin-language-server = {
              enable = false;
              package = null;
            };
            leanls = {
              enable = false;
              package = null;
            };
            ltex = {
              enable = false;
              package = null;
            };
            lua-ls = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            marksman = {
              enable = false;
              package = null;
            };
            metals = {
              enable = false;
              package = null;
            };
            nil-ls = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            nixd = {
              enable = false;
              package = null;
            };
            nushell = {
              enable = false;
              package = null;
            };
            ols = {
              enable = false;
              package = null; # FAILED
            };
            omnisharp = {
              enable = false;
              package = null;
            };
            perlpls = {
              enable = false;
              package = null;
            };
            pest-ls = {
              enable = false;
              package = null;
            };
            phpactor = {
              enable = false;
              package = null;
            };
            prismals = {
              enable = false;
              package = null;
            };
            prolog-ls = {
              enable = false;
              package = null;
            };
            pylsp = {
              enable = false;
              package = null;
            };
            pylyzer = {
              enable = false;
              package = null;
            };
            pyright = {
              #lsp - pyright
              #linter - flake8
              #formatter - black
              enable = true;
              package = null; # set to pkgs.packagename
            };
            rnix-lsp = {
              enable = false; # using nil_ls instead!
              package = null;
            };
            ruff-lsp = {
              enable = false;
              package = null;
            };
            rust-analyzer = {
              enable = true;
              package = null; # set to pkgs.packagename
              installCargo = true;
              installRustc = true;
            };
            solargraph = {
              enable = false;
              package = null;
            };
            sourcekit = {
              # Swift and C-based languages
              enable = true;
              # package = null; # set to pkgs.packagename # FAILED TO COMPILE ON NIXOS
            };
            svelte = {
              enable = false;
              package = null;
            };
            tailwindcss = {
              enable = false;
              package = null;
            };
            taplo = {
              enable = false;
              package = null;
            };
            templ = {
              enable = false;
              package = null;
            };
            terraformls = {
              enable = false;
              package = null;
            };
            texlab = {
              enable = false;
              package = null;
            };
            tsserver = {
              enable = true;
              package = null; # set to pkgs.packagename
            };
            typst-lsp = {
              enable = false;
              package = null;
            };
            vls = {
              enable = false;
              package = null;
            };
            volar = {
              enable = false;
              package = null;
            };
            vuels = {
              enable = false;
              package = null;
            };
            yamlls = {
              enable = false;
              package = null;
            };
            zls = {
              enable = false;
              package = null;
            };
          };
        };
        lsp-lines.enable = false; # damn annoyying
        lspkind.enable = true;

        # treesitter conf
        treesitter = {
          enable = true;
          folding = true; 
          # zc to close a fold
          # zo to open a fold
          # zM to close all folds
          # zR to open all folds
          indent = true;
          incrementalSelection = {
            enable = true;
            keymaps = {
              initSelection = "gnn";
              nodeDecremental = "grm";
              nodeIncremental = "grn";
              scopeIncremental = "grc";
            };
          };
        };

        treesitter-context = {
          enable = true;
          settings = {
            max_lines = 5; # limit to not hog up screenspace.
          };
        };

        nvim-ufo = {
          enable = true;
          enableGetFoldVirtText = true;
          closeFoldKinds = {
            imports = true;
            comment = true;
          };
          foldVirtTextHandler = ''
            function(virtText, lnum, endLnum, width, truncate)
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
                  -- str width returned from truncate() may less than 2nd argument, need padding
                  if curWidth + chunkWidth < targetWidth then
                    suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                  end
                  break
                end
                curWidth = curWidth + chunkWidth
              end
              table.insert(newVirtText, {suffix, 'MoreMsg'})
              return newVirtText
            end
          '';
          openFoldHlTimeout = 300;
          providerSelector = "function(bufnr, filetype, buftype) return {'treesitter', 'indent'} end";
        };
        
        statuscol = {
          enable = true;
          settings = {
            segments = [
              {
                text = [
                  "%s"
                ];
                click = "v:lua.ScSa";
              }
              {
                text = [
                  {
                    __raw = "function(args) return require('statuscol.builtin').lnumfunc(args) end";
                  }
                ];
                click = "v:lua.ScLa";
              }
              {
                text = [
                  " "
                  {
                    __raw = "require('statuscol.builtin').foldfunc";
                  }
                  " "
                ];
                condition = [
                  {
                    __raw = "require('statuscol.builtin').not_empty";
                  }
                  true
                  {
                    __raw = "require('statuscol.builtin').not_empty";
                  }
                ];
                click = "v:lua.ScFa";
              }
            ];
            clickmod = "c";
            clickhandlers = {
              Lnum = "require('statuscol.builtin').lnum_click";
              FoldClose = "require('statuscol.builtin').foldclose_click";
              FoldOpen = "require('statuscol.builtin').foldopen_click";
              FoldOther = "require('statuscol.builtin').foldother_click";
              DapBreakpointRejected = "require('statuscol.builtin').toggle_breakpoint";
              DapBreakpoint = "require('statuscol.builtin').toggle_breakpoint";
              DapBreakpointCondition = "require('statuscol.builtin').toggle_breakpoint";
              DiagnosticSignError = "require('statuscol.builtin').diagnostic_click";
              DiagnosticSignHint = "require('statuscol.builtin').diagnostic_click";
              DiagnosticSignInfo = "require('statuscol.builtin').diagnostic_click";
              DiagnosticSignWarn = "require('statuscol.builtin').diagnostic_click";
              GitSignsTopdelete = "require('statuscol.builtin').gitsigns_click";
              GitSignsUntracked = "require('statuscol.builtin').gitsigns_click";
              GitSignsAdd = "require('statuscol.builtin').gitsigns_click";
              GitSignsChange = "require('statuscol.builtin').gitsigns_click";
              GitSignsChangedelete = "require('statuscol.builtin').gitsigns_click";
              GitSignsDelete = "require('statuscol.builtin').gitsigns_click";
              gitsigns_extmark_signs_ = "require('statuscol.builtin').gitsigns_click";
            };
          };
        };
        
        # Filetree
        nvim-tree = {
          enable = true;
          autoClose = true;
          actions.openFile.quitOnOpen = true; # close on file open
          tab.sync.close = true;
          tab.sync.open = true;
          renderer.addTrailing = false;
        };

        # file search/fuzzyfinder
        telescope = {
          enable = true;
          #keymaps = {

          # "<C-p>" = {
          #   action = "git_files";
          #   desc = "Telescope Git Files";
          #    };
          #   "<leader>fg" = "live_grep";
          #};
        };

        # code-completion
        # cmp-nvim-lua.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        cmp-zsh.enable = true;
        intellitab.enable = true;

        # AI code-completion tools
        # codeium-nvim.enable = false;
        #copilot-cmp.enable = true;
        # copilot-lua = {
        #   enable = true;
        #   suggestion.enabled = false;
        # };
        # copilot-lua.panel = {
        #   enabled = false;
        #   autoRefresh = true;
        # };
        auto-save.enable = false;

        # git and revisioning
        # gitgutter.enable = true;

        # statusbar
        lualine = {
          enable = true;
          sections.lualine_c = [ "lsp_progress" ]; # Install lsp_progress!
        };
        noice.lsp.progress.enabled = true;

        # nvim window tabs!
        bufferline.enable = true;

        ## VISUAL FIXES
        # startup screen #FIXME: USE TOILET BANNER TO SAY HELLO!
        startup.enable = false;
        startify = {
          enable = true;
          settings = {
            change_to_dir = false;
            custom_header = [
              ""
              "     ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "     ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "     ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "     ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "     ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];
            fortune_use_unicode = true;
            lists = [
              {
                type = "files";
                header = [ "   MRU" ];
              }
              {
                type = "dir";
                header = [ { __raw = "'   MRU' .. vim.loop.cwd()"; } ];
              }
              {
                type = "sessions";
                header = [ "   Sessions" ];
              }
              {
                type = "bookmarks";
                header = [ "   Bookmarks" ];
              }
              {
                type = "commands";
                header = [ "   Commands" ];
              }
            ];
          };
        };
          #commenting
        comment = {
          enable = true;
          settings.toggler.line = if pkgs.stdenv.isDarwin then "<D-/>" else "<C-/>";
        };

        # outline code blocks
        indent-blankline = {
          enable = true;
          settings = {
            exclude = {
              # FIXME: ADD FileTree and CHADTREE!!!
              buftypes = [
                "terminal"
                "nofile"
                "quickfix"
                "prompt"
              ];
              filetypes = [
                "lspinfo"
                "packer"
                "checkhealth"
                "help"
                "man"
                "gitcommit"
                "TelescopePrompt"
                "TelescopeResults"
                "''"
                "nvimtree"
                "startify"
                "dashboard"
              ];
            };
            indent = {
              char = "▏";
              tab_char = null;
              highlight = null; # "|hl-IblIndent|"
            };
            scope = {
              enabled = true;
              char = null; # use indent.char
              highlight = null; # Shows an underline on the first line of the scope
              show_exact_scope = true; # Shows an underline on the first line of the scope starting at the exact start of the scope
            };
            whitespace = {
              highlight = null; # use default |hl-IblWhitespace|
              remove_blankline_trail = true; # set false?
            };
          };
        };

        #Note-taking
        obsidian = {
          enable = false; # Cross that bridge when we get there...
          settings = {
            completion = {
              min_chars = 2;
              nvim_cmp = true;
            };
            new_notes_location = "current_dir";
            workspaces = [
              {
                name = "work";
                path = "~/obsidian/work";
              }
              {
                name = "school";
                path = "~/obsidian/school";
              }
            ];
          };
        };
        neorg = {
          enable = true;
          modules = {
            #  require('neorg').setup {
            #    load = {
            #      ["core.defaults"] = {}, -- 
            #      ["core.concealer"] = {}, -- Allows for use of icons
            #    };
            #  }
            #}
            "core.defaults" = {
              # Load all the default modules
              #__empty = null;
            };
            "core.concealer" = {
              # Allows for the use of icons
            };
            "core.dirman" = {
              # idk what this does
              #config = {
              #  workspaces = {
              #    home = "~/notes/home";
              #    work = "~/notes/work";
              #  };
              #};
            };
          };
        };
      };

      colorschemes.base16 = {
        enable = true;
        colorscheme =
          let
            inherit (config.colorScheme) colors;
          in
          {
            # use nix-colors
            base00 = "#${colors.base00}";
            base01 = "#${colors.base01}";
            base02 = "#${colors.base02}";
            base03 = "#${colors.base03}";
            base04 = "#${colors.base04}";
            base05 = "#${colors.base05}";
            base06 = "#${colors.base06}";
            base07 = "#${colors.base07}";
            base08 = "#${colors.base08}";
            base09 = "#${colors.base09}";
            base0A = "#${colors.base0A}";
            base0B = "#${colors.base0B}";
            base0C = "#${colors.base0C}";
            base0D = "#${colors.base0D}";
            base0E = "#${colors.base0E}";
            base0F = "#${colors.base0F}";
          };
      };

      extraPlugins = with pkgs.vimPlugins; [
        #{
        #  plugin = nvim-scrollbar;
        #  config = toLuaFile ./plugin/scrollbar.lua;
        #}
        {
          plugin = nvim-scrollview;
          config = toLuaFile ./plugin/scrollview.lua;
        }

        # LSP
        #{
        #  plugin = nvim-lspconfig;
        #  config = toLuaFile ./plugin/lsp.lua;
        #}

        # FIXME: y u no worky? >:(
        # lsp-status-nvim # FIXME: What about lspinfo?
        # lazy-lsp-nvim # FIXME: LEARN MORE
        # asyncomplete-lsp-vim # FIXME: Learn more
        {
          plugin = nvim-cmp;
          config = toLuaFile ./plugin/cmp.lua;
        }
        #cmp-nvim-lsp # FIXME: Learn more
        #cmp-nvim-lsp-document-symbol 
        #cmp-nvim-lsp-signature-help

        nvim-web-devicons # optional, for file icons

        # Code Snippits
        luasnip # FIXME: Do I need this too? NEEDED
        # cmp-nvim-lsp # FIXME: What's this? NEEDED
        friendly-snippets
        #cmp_luasnip # completion for lua snippits

        #{
        #  plugin = pkgs.vimPlugins.cmp-nvim-tags;
        #  config = toLuaFile ./plugin/cmp-tags.lua;
        #}

        # # Visual Fixes
        # {
        #   plugin = feline-nvim;
        #   config = let inherit (config.colorscheme) colors; in
        #   toLuaFile ./plugin/feline.lua;
        # }

        # {
        #   plugin = winbar-nvim;
        #   config = toLuaFile ./plugin/winbar.lua;
        # }

        # {
        #   plugin = indent-blankline-nvim; # lines to identify codeblocks
        #   config = toLuaFile ./plugin/indent-blankline.lua;
        # }
        # Behavior Fixes
        vim-autoswap
        neodev-nvim # FIXME: WTF is neodev-nvim? NEEDED

        # Fuzzy Search Tool
        #telescope-fzf-native-nvim # FIXME: How do I use?

        # Syntax Highlighting
        #vim-nix # better highlighting for nix files

        # Emacs Org for nvim
        #{
        #  plugin = neorg;
        #  config = toLuaFile ./plugin/neorg.lua;
        #}
        #neorg-telescope
      ];
    };
}
