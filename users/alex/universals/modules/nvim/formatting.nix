{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Enable lsp-format for none-ls integration
    lsp-format.enable = true;

    preview = {
      enable = true;
      autoLoad = true;
    };

    none-ls = {
      enable = true;
      enableLspFormat = true;
      autoLoad = true;
      sources = {
        formatting = {
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
        };
        diagnostics.checkstyle = {
          enable = true;
          settings = {
            extra_args = [
              "-c"
              "${./plugin/checkstyle/google_checks.xml}"
            ];
            diagnostics_format = "[#{c}] #{m} (#{s})";
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
          linter = [ "statix" ];
        };
        java = {
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
        };
        typescript = {
          formatter = [ "prettier" ];
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
          formatter = [ "uncrustify" ];
          linter = [ "gcc" ];
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
  };

  # Enable format on save
  programs.nixvim.autoCmd = [
    {
      event = [ "BufWritePre" ];
      pattern = "*";
      callback = {
        __raw = ''
          function()
            -- Skip if we're in insert mode (user is still typing)
            if vim.api.nvim_get_mode().mode == 'i' then
              return
            end

            -- Only format if LSP is attached and supports formatting
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            for _, client in ipairs(clients) do
              if client.supports_method("textDocument/formatting") then
                vim.lsp.buf.format({
                  async = false,
                  timeout_ms = 2000,
                })
                break
              end
            end
          end
        '';
      };
    }
  ];

  # Add keymaps for manual formatting
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>f";
      action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>";
      options.desc = "Format buffer";
    }
    {
      mode = "v";
      key = "<leader>f";
      action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>";
      options.desc = "Format selection";
    }
  ];
}
