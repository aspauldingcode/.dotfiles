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
      nixpkgs.pkgs = pkgs.unstable;
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
            };
          };
          settings = {
            notify_format = "[null-ls] %s";
            diagnostics_format = "[#{c}] #{m} (#{s})";
            temp_dir = "/tmp";
            update_in_insert = false;
          };
        };
        efmls-configs = {
          enable = true;
          setup = {
            all = {
              linter = [
                "codespell"
              ];
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
              linter = [
                "codespell"
              ];
            };
            python = {
              formatter = [ "black" ];
              linter = [ "flake8" ];
            };
            markdown = {
              formatter = [ "mdformat" ];
              linter = [ "markdownlint" ];
            };
            lua = {
              formatter = [ "lua_format" ];
              linter = [ "luacheck" ];
            };
            bash = {
              formatter = [ "beautysh" ];
              linter = [
                "shellcheck"
                "bashate"
              ];
            };
            javascript = {
              formatter = [ "prettier" ];
              # linter = [ "eslint" ];
            };
            typescript = {
              formatter = [ "prettier" ];
              # linter = [ "eslint" ];
            };
            css = {
              formatter = [ "prettier" ];
              linter = [ "stylelint" ];
            };
            html = {
              formatter = [ "prettier" ];
              linter = [ "codespell" ];
            };
            yaml = {
              formatter = [ "prettier" ];
              linter = [ "yamllint" ];
            };
            json = {
              formatter = [ "prettier" ];
              linter = [
                "codespell"
              ];
            };
            rust = {
              formatter = [ "rustfmt" ];
              linter = [
                "codespell"
              ];
            };
            go = {
              formatter = [ "gofmt" ];
              linter = [ "golangci_lint" ];
            };
            c = {
              formatter = [ "uncrustify" ]; # one of “astyle”, “clang_format”, “clang_tidy”, “uncrustify”
              linter = [ "gcc" ]; # one of “clang_format”, “clang_tidy”, “cppcheck”, “cpplint”, “flawfinder”, “gcc”, “alex”, “codespell”, “cspell”, “languagetool”, “proselint”, “redpen”, “textlint”, “vale”, “write_good”
            };
            cpp = {
              formatter = [ "uncrustify" ];
              linter = [ "gcc" ];
            };
          };
          toolPackages = {
            actionlint = pkgs.unstable.actionlint;
            alejandra = pkgs.unstable.alejandra;
            alex = pkgs.unstable.nodePackages.alex;
            ameba = pkgs.unstable.ameba;
            ansible_lint = pkgs.unstable.ansible-lint;
            astyle = pkgs.unstable.astyle;
            autopep8 = pkgs.unstable.python3.pkgs.autopep8;
            bashate = pkgs.unstable.bashate;
            beautysh = pkgs.unstable.beautysh;
            biome = pkgs.unstable.biome;
            black = pkgs.unstable.black;
            buf = pkgs.unstable.buf;
            cbfmt = pkgs.unstable.cbfmt;
            checkmake = pkgs.unstable.checkmake;
            chktex = pkgs.unstable.texliveMedium;
            clang_format = pkgs.unstable.clang-tools;
            clang_tidy = pkgs.unstable.clang-tools;
            clazy = pkgs.unstable.clazy;
            clj_kondo = pkgs.unstable.clj-kondo;
            cmake_lint = pkgs.unstable.cmake-format;
            codespell = pkgs.unstable.codespell;
            cppcheck = pkgs.unstable.cppcheck;
            cpplint = pkgs.unstable.cpplint;
            dartfmt = pkgs.unstable.dart;
            dfmt = pkgs.unstable.dfmt;
            djlint = pkgs.unstable.djlint;
            dmd = pkgs.unstable.dmd;
            dotnet_format = pkgs.unstable.dotnet-runtime;
            dprint = pkgs.unstable.dprint;
            # eslint = pkgs.unstable.eslint;
            eslint_d = pkgs.unstable.nodePackages.eslint_d;
            fish = pkgs.unstable.fish;
            fish_indent = pkgs.unstable.fish;
            flake8 = pkgs.unstable.python3.pkgs.flake8;
            flawfinder = pkgs.unstable.flawfinder;
            fnlfmt = pkgs.unstable.fnlfmt;
            fourmolu = pkgs.unstable.haskellPackages.fourmolu;
            gcc = pkgs.unstable.gcc;
            gitlint = pkgs.unstable.gitlint;
            go_revive = pkgs.unstable.revive;
            gofmt = pkgs.unstable.go;
            gofumpt = pkgs.unstable.gofumpt;
            goimports = pkgs.unstable.go-tools;
            golangci_lint = pkgs.unstable.golangci-lint;
            golines = pkgs.unstable.golines;
            golint = pkgs.unstable.golint;
            google_java_format = pkgs.unstable.google-java-format;
            hadolint = pkgs.unstable.hadolint;
            isort = pkgs.unstable.isort;
            joker = pkgs.unstable.joker;
            jq = pkgs.unstable.jq;
            languagetool = pkgs.unstable.languagetool;
            latexindent = pkgs.unstable.texliveMedium;
            lua_format = pkgs.unstable.luaformatter;
            luacheck = pkgs.luaPackages.luacheck;
            markdownlint = pkgs.unstable.markdownlint-cli;
            mcs = pkgs.unstable.mono;
            mdformat = pkgs.unstable.python3.pkgs.mdformat;
            mypy = pkgs.unstable.mypy;
            nixfmt = pkgs.unstable.nixfmt-classic;
            phan = pkgs.unstable.phpPackages.phan;
            php = pkgs.unstable.php;
            php_cs_fixer = pkgs.unstable.phpPackages.php-cs-fixer;
            phpcbf = pkgs.unstable.phpPackages.php-codesniffer;
            phpcs = pkgs.unstable.phpPackages.php-codesniffer;
            phpstan = pkgs.unstable.phpPackages.phpstan;
            prettier = pkgs.unstable.nodePackages.prettier;
            prettier_d = pkgs.unstable.prettierd;
            prettypst = pkgs.unstable.prettypst;
            proselint = pkgs.unstable.proselint;
            protolint = pkgs.unstable.protolint;
            psalm = pkgs.unstable.phpPackages.psalm;
            pylint = pkgs.unstable.pylint;
            rubocop = pkgs.unstable.rubocop;
            ruff = pkgs.unstable.ruff;
            rustfmt = pkgs.unstable.rustfmt;
            scalafmt = pkgs.unstable.scalafmt;
            selene = pkgs.unstable.selene;
            shellcheck = pkgs.unstable.shellcheck;
            shellharden = pkgs.unstable.shellharden;
            shfmt = pkgs.unstable.shfmt;
            slither = pkgs.unstable.slither-analyzer;
            smlfmt = pkgs.unstable.smlfmt;
            sql-formatter = pkgs.unstable.nodePackages.sql-formatter;
            sqlfluff = pkgs.unstable.sqlfluff;
            staticcheck = pkgs.unstable.go-tools;
            statix = pkgs.unstable.statix;
            stylelint = pkgs.unstable.nodePackages.stylelint;
            stylua = pkgs.unstable.stylua;
            taplo = pkgs.unstable.taplo;
            terraform_fmt = pkgs.unstable.terraform;
            textlint = pkgs.unstable.nodePackages.textlint;
            typstfmt = pkgs.unstable.typstfmt;
            typstyle = pkgs.unstable.typstyle;
            uncrustify = pkgs.unstable.uncrustify;
            vale = pkgs.unstable.vale;
            vint = pkgs.unstable.vim-vint;
            vulture = pkgs.unstable.python3.pkgs.vulture;
            write_good = pkgs.unstable.write-good;
            yamllint = pkgs.unstable.yamllint;
            yapf = pkgs.unstable.yapf;
            yq = pkgs.unstable.yq-go;
          };
        };
        notify = {
          enable = true;
          package = pkgs.vimPlugins.nvim-notify;
          settings = {
            # backgroundColour = "";
            extraOptions = { };
            fps = null;
            level = null;
            max_height = 20;
            max_width = 80;
            minimum_width = 20;
            on_close = null;
            on_open = null;
            render = "wrapped-compact"; # Type: null or one of “default”, “minimal”, “simple”, “compact”, “wrapped-compact” or raw lua code
            stages = null;
            timeout = 3500;
            top_down = true;
            icons = {
              debug = "";
              error = "";
              info = "";
              trace = "✎";
              warn = "";
            };
          };
        };
        gitsigns.enable = true;
        lsp = {
          enable = true;
          servers = {
            # https://nix-community.github.io/nixvim/plugins/lsp/
            ansiblels = {
              enable = true;
              package = pkgs.unstable.ansible-language-server;
            };
            astro = {
              enable = false;
              package = pkgs.unstable.astro-language-server;
            };
            bashls = {
              enable = true;
              package = pkgs.unstable.bash-language-server;
            };
            beancount = {
              enable = false;
              package = pkgs.unstable.beancount-language-server;
            };
            biome = {
              enable = false;
              package = pkgs.unstable.biome;
            };
            ccls = {
              # C/C++/Objective-C language server
              enable = true;
              package = pkgs.unstable.ccls;
            };
            clangd = {
              enable = true;
              package = pkgs.unstable.clang-tools;
            };
            clojure_lsp = {
              enable = false;
              package = pkgs.unstable.clojure-lsp;
            };
            cmake = {
              enable = true;
              package = pkgs.unstable.cmake-language-server;
            };
            csharp_ls = {
              enable = false;
              package = pkgs.unstable.csharp-ls; # NOT AVAILABLE on DARWIN
            };
            cssls = {
              enable = true;
              package = pkgs.unstable.nodePackages.vscode-langservers-extracted; # CSS language server
            };
            dagger = {
              enable = false;
              package = pkgs.unstable.dagger;
            };
            dartls = {
              enable = false;
              package = pkgs.unstable.dart;
            };
            denols = {
              enable = false;
              package = pkgs.unstable.deno;
            };
            dhall_lsp_server = {
              enable = false;
              package = pkgs.unstable.dhall-lsp-server;
            };
            digestif = {
              enable = false;
              package = pkgs.unstable.texlivePackages.digestif;
            };
            dockerls = {
              enable = false;
              package = pkgs.unstable.dockerfile-language-server-nodejs;
            };
            efm = {
              enable = true;
              package = pkgs.unstable.efm-langserver;
            };
            elixirls = {
              enable = false;
              package = pkgs.unstable.elixir-ls;
            };
            elmls = {
              enable = false;
              package = pkgs.unstable.elmPackages.elm-language-server;
            };
            emmet_ls = {
              enable = false;
              package = pkgs.unstable.emmet-ls;
            };
            eslint = {
              enable = false; # Disable eslint language server
              # package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
            };
            fsautocomplete = {
              enable = false;
              package = pkgs.unstable.fsautocomplete; # DOESN'T COMPILE ON DARWIN
            };
            futhark_lsp = {
              enable = false;
              package = pkgs.unstable.futhark;
            };
            gdscript = {
              enable = false;
              package = pkgs.unstable.godot;
            };
            gleam = {
              enable = false;
              package = pkgs.unstable.gleam;
            };
            gopls = {
              enable = false;
              package = pkgs.unstable.gopls;
            };
            graphql = {
              enable = false;
              package = pkgs.unstable.nodePackages.graphql-language-service-cli;
            };
            hls = {
              enable = false;
              package = pkgs.unstable.haskell-language-server;
            };
            html = {
              enable = false;
              package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
            };
            htmx = {
              enable = true;
              package = pkgs.unstable.htmx-lsp;
            };
            intelephense = {
              enable = false;
              package = pkgs.unstable.nodePackages.intelephense;
            };
            java_language_server = {
              # USING JDTLS instead!
              enable = false;
              package = pkgs.unstable.java-language-server;
            };
            jsonls = {
              enable = true;
              package = pkgs.unstable.nodePackages.vscode-langservers-extracted;
            };
            julials = {
              enable = false;
              package = pkgs.unstable.julia-bin;
            };
            kotlin_language_server = {
              enable = false;
              package = pkgs.unstable.kotlin-language-server;
            };
            leanls = {
              enable = false;
              package = pkgs.unstable.lean4;
            };
            ltex = {
              enable = false;
              package = pkgs.unstable.ltex-ls;
            };
            lua_ls = {
              enable = true;
              package = pkgs.unstable.lua-language-server;
            };
            marksman = {
              enable = false;
              package = pkgs.unstable.marksman;
            };
            metals = {
              enable = false;
              package = pkgs.unstable.metals;
            };
            nil_ls = {
              enable = true;
              package = pkgs.unstable.nil;
            };
            nixd = {
              enable = false;
              package = pkgs.unstable.nixd;
            };
            nushell = {
              enable = false;
              package = pkgs.unstable.nushell;
            };
            ols = {
              enable = false;
              package = pkgs.unstable.ols; # FAILED
            };
            omnisharp = {
              enable = false;
              package = pkgs.unstable.omnisharp-roslyn;
            };
            perlpls = {
              enable = false;
              package = pkgs.unstable.perl534Packages.PLS;
            };
            pest_ls = {
              enable = false;
              package = pkgs.unstable.pest-language-server;
            };
            phpactor = {
              enable = false;
              package = pkgs.unstable.phpactor;
            };
            prismals = {
              enable = false;
              package = pkgs.unstable.nodePackages."@prisma/language-server";
            };
            prolog_ls = {
              enable = false;
              package = pkgs.unstable.swiProlog;
            };
            pylsp = {
              enable = false;
              package = pkgs.unstable.python3Packages.python-lsp-server;
            };
            pylyzer = {
              enable = false;
              package = pkgs.unstable.pylyzer;
            };
            pyright = {
              #lsp - pyright
              #linter - flake8
              #formatter - black
              enable = true;
              package = pkgs.unstable.pyright;
            };
            rnix = {
              enable = false; # using nil_ls instead!
              package = pkgs.unstable.rnix-lsp;
            };
            ruff_lsp = {
              enable = false;
              package = pkgs.unstable.ruff-lsp;
            };
            rust_analyzer = {
              enable = true;
              package = pkgs.unstable.rust-analyzer;
              installCargo = true;
              installRustc = true;
            };
            solargraph = {
              enable = false;
              package = pkgs.unstable.solargraph;
            };
            sourcekit = {
              # Swift and C-based languages
              enable = false; # requires compilation of swift? NO THANKS!
              # package = pkgs.unstable.sourcekit-lsp; # FAILED TO COMPILE ON NIXOS
            };
            svelte = {
              enable = false;
              package = pkgs.unstable.nodePackages.svelte-language-server;
            };
            tailwindcss = {
              enable = false;
              package = pkgs.unstable.nodePackages."@tailwindcss/language-server";
            };
            taplo = {
              enable = true; # for TOML
              package = pkgs.unstable.taplo;
              autostart = true;
              filetypes = [ "toml" ]; # Include .toml files
              rootDir = {
                __raw = "require('lspconfig.util').root_pattern('*.toml', '.git')";
              }; # IMPORTANT: this is required for taplo LSP to work in non-git repositories
            };
            templ = {
              enable = false;
              package = pkgs.unstable.templ;
            };
            terraformls = {
              enable = false;
              package = pkgs.unstable.terraform-ls;
            };
            texlab = {
              enable = true;
              package = pkgs.unstable.texlab;
            };
            ts_ls = {
              enable = true;
              package = pkgs.unstable.nodePackages.typescript-language-server;
            };
            typst_lsp = {
              enable = false;
              package = pkgs.unstable.typst-lsp;
            };
            vls = {
              enable = false;
              package = pkgs.unstable.vls;
            };
            volar = {
              enable = false;
              package = pkgs.unstable.nodePackages."@volar/vue-language-server";
            };
            vuels = {
              enable = false;
              package = pkgs.unstable.nodePackages.vue-language-server;
            };
            yamlls = {
              enable = true;
              package = pkgs.unstable.yaml-language-server;
            };
            zls = {
              enable = false;
              package = pkgs.unstable.zls;
            };
          };
        };
        web-devicons.enable = true;
        lsp-lines.enable = false; # damn annoyying
        lspkind.enable = true;

        # color previews
        colorizer.enable = true;

        # better nix highlighting with vim-nix
        nix.enable = true;

        # treesitter conf
        treesitter = {
          enable = true;
          settings = {
            indent = {
              enable = true;
            };
            incrementalSelection = {
              enable = true;
              keymaps = {
                initSelection = false;
                nodeDecremental = "grm";
                nodeIncremental = "grn";
                scopeIncremental = "grc";
              };
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
          package = pkgs.unstable.vimPlugins.nvim-ufo;
          settings = {
            enable_get_fold_virt_text = true;
            close_fold_kinds_for_ft = {
              imports = true;
              comment = true;
            };
            fold_virt_text_handler = ''
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
            open_fold_hl_timeout = 300;
            provider_selector = "function(bufnr, filetype, buftype) return {'treesitter', 'indent'} end";
          };
        };

        statuscol = {
          enable = true;
          settings = {
            segments = [
              {
                text = [ "%s" ];
                click = "v:lua.ScSa";
              }
              {
                text = [ { __raw = "function(args) return require('statuscol.builtin').lnumfunc(args) end"; } ];
                click = "v:lua.ScLa";
              }
              {
                text = [
                  " "
                  { __raw = "require('statuscol.builtin').foldfunc"; }
                  " "
                ];
                condition = [
                  { __raw = "require('statuscol.builtin').not_empty"; }
                  true
                  { __raw = "require('statuscol.builtin').not_empty"; }
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
          # package = pkgs.vimPlugins.nvim-tree-lua;
          autoClose = false;
          autoReloadOnWrite = null;
          disableNetrw = null;
          extraOptions = { };
          gitPackage = pkgs.git;
          hijackCursor = null;
          hijackNetrw = null;
          hijackUnnamedBufferWhenOpening = null;
          ignoreBufferOnSetup = false;
          ignoreFtOnSetup = [ ];
          onAttach = null;
          openOnSetup = true;
          openOnSetupFile = false;
          preferStartupRoot = null;
          reloadOnBufenter = null;
          respectBufCwd = null;
          rootDirs = null;
          selectPrompts = null;
          sortBy = null;
          syncRootWithCwd = null;
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
        # cmp-nvim-lsp.enable = true;
        # cmp-nvim-lsp-signature-help.enable = true;
        cmp-zsh.enable = true;
        # intellitab.enable = true;

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
          settings = {
            sections.lualine_c = [ "lsp_progress" ]; # Install lsp_progress!
            separators = {
              left = "";
              right = "";
            };
          };
        };
        noice.settings.lsp.progress.enabled = true;

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
          settings.opleader.line = if pkgs.stdenv.isDarwin then "<D-/>" else "<C-/>";
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
            #completion = {
            #  min_chars = 2;
            #nvim_cmp = true;
            #};
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
          settings.load = {
            "core.defaults" = {
              # Load all the default modules
            };
            "core.concealer" = {
              # Allows for the use of icons
            };
            "core.dirman" = {
              # Manages workspaces and directories
            };
          };
        };

        markdown-preview = {
          enable = true;
          settings = {
            auto_close = 1;
            auto_start = 1;
            browser = "firefox";
            browserfunc = "";
            combine_preview = 0;
            combine_preview_auto_refresh = 1;
            command_for_global = 0;
            echo_preview_url = 1;
            filetypes = [ "markdown" ];
            highlight_css = "";
            images_path = "";
            markdown_css = "";
            open_ip = "";
            open_to_the_world = 0;
            page_title = "「Markdown Preview」";
            port = "8080";
            refresh_slow = 0;
            theme = "dark";
          };
        };

        # Animation
        # Smooth scrolling animations
        neoscroll = {
          enable = true;
          settings = {
            # All default mappings
            mappings = [
              "<C-u>" # Half page up
              "<C-d>" # Half page down
              "<C-b>" # Page up
              "<C-f>" # Page down
              "<C-y>" # Line up
              "<C-e>" # Line down
              "zt" # Current line to top
              "zz" # Current line to middle
              "zb" # Current line to bottom
            ];
            # Hide cursor while scrolling for better experience
            hide_cursor = true;
            # Stop at EOF when scrolling down
            stop_eof = true;
            # Don't maintain scrolloff distance during scroll
            respect_scrolloff = false;
            # The cursor will keep scrolling even if window can't scroll further
            cursor_scrolls_alone = true;
            # Use quadratic easing for smooth acceleration/deceleration
            easing = "quadratic";
            # No performance mode optimizations
            performance_mode = false;
            # No custom hooks
            pre_hook = null;
            post_hook = null;
            # Global duration multiplier
            duration_multiplier = 1.0;
            # Ignore these events while scrolling
            ignored_events = [
              "WinScrolled"
              "CursorMoved"
            ];
          };
        };

        # nvim-mini cursor animations.
        mini = {
          enable = true;
          modules = {
            animate = {
              cursor = {
                enable = true;
                timing = {
                  __raw = "require('mini.animate').gen_timing.linear({ duration = 100, unit = 'total' })";
                };
              };
              scroll = {
                enable = true;
                timing = {
                  __raw = "require('mini.animate').gen_timing.linear({ duration = 150, unit = 'total' })";
                };
              };
              resize = {
                enable = true;
                timing = {
                  __raw = "require('mini.animate').gen_timing.linear({ duration = 100, unit = 'total' })";
                };
              };
              open = {
                enable = true;
                timing = {
                  __raw = "require('mini.animate').gen_timing.linear({ duration = 100, unit = 'total' })";
                };
              };
              close = {
                enable = true;
                timing = {
                  __raw = "require('mini.animate').gen_timing.linear({ duration = 100, unit = 'total' })";
                };
              };
            };
          };
        };

        # nvim-specs #FIXME: Learn more - idfk how to use.
        specs = {
          enable = true;
          settings = {
            show_jumps = true;
            min_jump = 30;
            popup = {
              delay_ms = 0; # delay before popup displays
              inc_ms = 10; # time increments used for fade/resize effects
              blend = 10; # starting blend, between 0-100 (fully transparent), see :h winblend
              width = 10;
              winhl = "PMenu";
              fader = "require('specs').linear_fader";
              resizer = "require('specs').shrink_resizer";
            };
            ignore_filetypes = { };
            ignore_buftypes = {
              nofile = true;
            };
          };
        };

        # cursor - like ai for neovim with Avante.nvim
        avante = {
          enable = true;
          autoLoad = true;
          package = pkgs.vimPlugins.avante-nvim;

          settings = {
            provider = "openai";
            auto_suggestions_frequency = "copilot";

            openai = {
              endpoint = "https://api.openai.com/v1";
              model = "gpt-4o";
              timeout = 30000;
              temperature = 0;
              max_tokens = 4096;
            };

            diff = {
              autojump = true;
              debug = false;
              list_opener = "copen";
            };

            highlights = {
              diff = {
                current = "DiffText";
                incoming = "DiffAdd";
              };
              signs = {
                AvanteInputPromptSign = "Question";
              };
            };

            hints.enabled = true;

            mappings = {
              diff = {
                next = "]x";
                prev = "[x";
                ours = "co";
                theirs = "ct";
                both = "cb";
                none = "c0";
              };
              jump = {
                next = "]]";
                prev = "[[";
              };
            };

            windows = {
              width = 30;
              wrap = true;
              sidebar_header = {
                rounded = true;
                align = "center";
              };
            };
          };
        };
      };

      colorschemes.base16 = {
        enable = true;
        colorscheme =
          let
            inherit (config.colorScheme) palette;
          in
          {
            # use nix-colors
            base00 = "#${palette.base00}";
            base01 = "#${palette.base01}";
            base02 = "#${palette.base02}";
            base03 = "#${palette.base03}";
            base04 = "#${palette.base04}";
            base05 = "#${palette.base05}";
            base06 = "#${palette.base06}";
            base07 = "#${palette.base07}";
            base08 = "#${palette.base08}";
            base09 = "#${palette.base09}";
            base0A = "#${palette.base0A}";
            base0B = "#${palette.base0B}";
            base0C = "#${palette.base0C}";
            base0D = "#${palette.base0D}";
            base0E = "#${palette.base0E}";
            base0F = "#${palette.base0F}";
          };
      };

      extraPlugins = with pkgs.vimPlugins; [
        {
          plugin = windows-nvim;
          config = toLuaFile ./plugin/windows-nvim.lua;
        }
        {
          plugin = animation-nvim;
          # config = toLuaFile ./plugin/animation-nvim.lua;
        }
        {
          plugin = middleclass;
          # config = toLuaFile ./plugin/middleclass.lua;
        }
        #{
        #  plugin = nvim-scrollbar;
        #  config = toLuaFile ./plugin/scrollbar.lua;
        #}
        {
          plugin = nvim-scrollview;
          config = toLuaFile ./plugin/scrollview.lua;
        }

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

        # nvim-web-devicons # optional, for file icons

        # Code Snippits
        luasnip # FIXME: Do I need this too? NEEDED
        # cmp-nvim-lsp # FIXME: What's this? NEEDED
        friendly-snippets
        #cmp_luasnip # completion for lua snippits

        # Behavior Fixes
        vim-autoswap
        neodev-nvim # FIXME: WTF is neodev-nvim? NEEDED

        # Fuzzy Search Tool
        #telescope-fzf-native-nvim # FIXME: How do I use?

        # Syntax Highlighting
        # vim-nix # better highlighting for nix files
      ];
    };
}
