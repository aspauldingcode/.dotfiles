{ config, pkgs, lib, nixvim, ... }: 

{
  imports = [
    nixvim.homeManagerModules.nixvim
  ];
  
    nixpkgs.config.allowUnsupportedSystemPredicate = pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
      "swiftformat" 
      "sourcekit-lsp" 
    ];

  # nixvim specific dependencies
  home.packages = with pkgs; [  
    # linters:
    pylint #python
    # python311Packages.flake8
    #ruff # python
    commitlint # git commits
    lint-staged # git stage
    sqlint # sql
    yamllint # yaml
    vim-vint # vimscript 
    statix # nix
    #nixpkgs-lint-community #nix with treesitter
    #nix-linter # nix
    cargo-toml-lint # cargo.toml
    eslint_d # fast eslint
    api-linter # linter for apis in protocol buffers
    ls-lint # directory name linter
    lua54Packages.luacheck # lua
    ktlint # kotlin
    rslint # ts, js
    djlint # html
    scss-lint # scss
    csslint # css
    cpplint # C++ static linter
    actionlint # github actions

    # formatters:
    black # python uncomprimising 
    luaformatter # lua
    rufo # ruby
    jsonfmt # json
    #nixpkgs-fmt # nix
    nixfmt # nix opinionated
    #alejandra # nix uncompromising
    google-java-format # java
    ktlint # kotlin java
    xcpretty # xcodebnuild
    # swiftformat # swift format and linter
    fop # xml
    xmlformat # xml
    commit-formatter # git
  ];

  programs.nixvim = 
  let 
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in 
  {
    enable = true;
    options = {
      number = true;         # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 8;        # Tab width should be 2
    };
    extraConfigLua = ''
    -- Print a little welcome message when nvim is opened!
    -- print("Hello world!")

    -- All my configuration options for nvim:
    ${builtins.readFile ./options.lua}
    '';
    globals.mapleader = ","; # Sets the leader key to comma
    keymaps = [ # https://github.com/nix-community/nixvim/tree/main#key-mappings
    {
      key = ";";
      action = ":";
    }
    {
      mode = "n";
      key = "<leader>m";
      options.silent = true;
      action = "<cmd>!make<CR>";
    }
  ];
  plugins = { 
    #JAVALSP
    nvim-jdtls = {
      enable = true;
      data =  "${config.xdg.cacheHome}/jdtls/workspace";
      configuration = "${config.xdg.cacheHome}/jdtls/config";
      initOptions = null;
      rootDir = { __raw = "require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'})"; };
      settings = null; 
      /*Here you can configure eclipse.jdt.ls specific settings.
      See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request 
      for a list of options.
      */
    };
    clangd-extensions.enable = true;
    lsp = {
      enable = true;
      servers = { # https://nix-community.github.io/nixvim/plugins/lsp/
      ansiblels = {
        enable = true;
        installLanguageServer = true;
      };
      /*astro = {
        enable = true;
        installLanguageServer = true;
      };
      bashls = {
        enable = true;
        installLanguageServer = true;
      };
      beancount = {
        enable = true;
        installLanguageServer = true;
      };
      biome = {
        enable = true;
        installLanguageServer = true;
      };
      ccls = {
        enable = true;
        installLanguageServer = true;
      };
      clangd = {
        enable = true;
        installLanguageServer = true;
      };
      clojure-lsp = {
        enable = true;
        installLanguageServer = true;
      };
      cmake = {
        enable = true;
        installLanguageServer = true;
      };
      csharp-ls = {
        enable = true;
        installLanguageServer = false; # NOT AVAILABLE on DARWIN
      };
      cssls = {
        enable = true;
        installLanguageServer = true;
      };
      dagger = {
        enable = true;
        installLanguageServer = true;
      };
      dartls = {
        enable = true;
        installLanguageServer = true;
      };
      denols = {
        enable = true;
        installLanguageServer = true;
      };
      dhall-lsp-server = {
        enable = true;
        installLanguageServer = true;
      };
      digestif = {
        enable = true;
        installLanguageServer = true;
      };
      dockerls = {
        enable = true;
        installLanguageServer = true;
      };
      efm = {
        enable = true;
        installLanguageServer = true;
      };
      elixirls = {
        enable = true;
        installLanguageServer = true;
      };
      elmls = {
        enable = true;
        installLanguageServer = true;
      };
      emmet_ls = {
        enable = true;
        installLanguageServer = true;
      };
      eslint = {
        enable = true;
        installLanguageServer = true;
      };
      fsautocomplete = {
        enable = true;
        installLanguageServer = false; # DOESN'T COMPILE ON DARWIN
      };
      futhark-lsp = {
        enable = true;
        installLanguageServer = true;
      };
      gdscript = {
        enable = true;
        installLanguageServer = true;
      };
      gleam = {
        enable = true;
        installLanguageServer = true;
      };
      gopls = {
        enable = true;
        installLanguageServer = true;
      };
      graphql = {
        enable = true;
        installLanguageServer = true;
      };
      hls = {
        enable = true;
        installLanguageServer = true;
      };
      html = {
        enable = true;
        installLanguageServer = true;
      };
      htmx = {
        enable = true;
        installLanguageServer = false; # FAILED
      };
      intelephense = {
        enable = true;
        installLanguageServer = true;
      };
      #java-language-server = { #USING JDTLS!
      #  enable = true;
      #  installLanguageServer = true;
      #};
      jsonls = {
        enable = true;
        installLanguageServer = true;
      };
      julials = {
        enable = true;
        installLanguageServer = true;
      };
      kotlin-language-server = {
        enable = true;
        installLanguageServer = true;
      };
      leanls = {
        enable = true;
        installLanguageServer = true;
      };
      ltex = {
        enable = true;
        installLanguageServer = true;
      };
      */
      lua-ls = {
        enable = true;
        installLanguageServer = true;
      };
      /*
      marksman = {
        enable = true;
        installLanguageServer = true;
      };
      metals = {
        enable = true;
        installLanguageServer = true;
      };
      */
      nil_ls = {
        enable = true;
        installLanguageServer = true;
      };
      /*
      nixd = {
        enable = true;
        installLanguageServer = true;
      };
      nushell = {
        enable = true;
        installLanguageServer = true;
      };
      ols = {
        enable = true;
        installLanguageServer = false; #FAILED
      };
      omnisharp = {
        enable = true;
        installLanguageServer = true;
      };
      perlpls = {
        enable = true;
        installLanguageServer = true;
      };
      pest_ls = {
        enable = true;
        installLanguageServer = true;
      };
      phpactor = {
        enable = true;
        installLanguageServer = true;
      };
      prismals = {
        enable = true;
        installLanguageServer = true;
      };
      prolog-ls = {
        enable = true;
        installLanguageServer = true;
      };
      pylsp = {
        enable = true;
        installLanguageServer = true;
      };
      pylyzer = {
        enable = true;
        installLanguageServer = true;
      };
      */
      pyright = {
        enable = true;
        installLanguageServer = true;
        #lsp - pyright
        #linter - flake8
        #formatter - black
      };
      /*
      rnix-lsp = {
        enable = false; # using nil_ls instead!
        installLanguageServer = true;
      };
      ruff-lsp = {
        enable = true;
        installLanguageServer = true;
      };
      */
      rust-analyzer = {
        enable = true;
        installLanguageServer = true;
        installCargo = true;
        installRustc = true;
      };
      # solargraph = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      sourcekit = {
        enable = true;
        installLanguageServer = false; # FAILED TO COMPILE ON NIXOS
      };
      /*svelte = {
        enable = true;
        installLanguageServer = true;
      };
      tailwindcss = {
        enable = true;
        installLanguageServer = true;
      };
      taplo = {
        enable = true;
        installLanguageServer = true;
      };
      templ = {
        enable = true;
        installLanguageServer = true;
      };
      terraformls = {
        enable = true;
        installLanguageServer = true;
      };
      texlab = {
        enable = true;
        installLanguageServer = true;
      };
      */
      tsserver = {
        enable = true;
        installLanguageServer = true;
      };
      /*
      typst-lsp = {
        enable = true;
        installLanguageServer = true;
      };
      vls = {
        enable = true;
        installLanguageServer = true;
      };
      volar = {
        enable = true;
        installLanguageServer = true;
      };
      vuels = {
        enable = true;
        installLanguageServer = true;
      };
      yamlls = {
        enable = true;
        installLanguageServer = true;
      };
      zls = {
        enable = true;
        installLanguageServer = true;
      };
      */
    };
  };
    # lsp-lines.enable = true;
    lspkind.enable = true;

    # Filetree
    chadtree.enable = true;

    # code-completion
    #cmp-nvim-lsp-signature-help.enable = true;
    #cmp-zsh.enable = true;

    # AI code-completion tools
    codeium-nvim.enable = true;
    copilot-cmp.enable = true;
    copilot-lua = {
      enable = true;
      suggestion.enabled = false;
    };
    copilot-lua.panel = {
      enabled = false;
      autoRefresh = true;
    };
    auto-save.enable = false;

    # git and revisioning 
    gitgutter.enable = true;

    # statusbar
    lualine = {
      enable=true;
      # sections.lualine_c = [ "lsp_progress" ]; # Install lsp_progress!
    };

    ## VISUAL FIXES
    # startup screen #FIXME: USE TOILET BANNER TO SAY HELLO!
    startup.enable = false;
    startify.enable = true;

    # outline code blocks
    indent-blankline = {
      enable = true;
      exclude = { #FIXME: ADD FileTree and CHADTREE!!!
      buftypes = [
        "terminal" "nofile" "quickfix" "prompt"
      ];
      filetypes = [ 
        "lspinfo" "packer" "checkhealth" "help" "man" "gitcommit" 
        "TelescopePrompt" "TelescopeResults" "\'\'" "nvimtree" "startify"
        "dashboard" 
      ];
    };
    indent = {
      char = "▏"; # Alternatives: https://github.com/lukas-reineke/indent-blankline.nvim/blob/12e92044d313c54c438bd786d11684c88f6f78cd/doc/indent_blankline.txt#L262
      tabChar = null;
      highlight = null; # "|hl-IblIndent|"
    };
    scope = {
      enabled = true;
      char = null; # use indent.char
      highlight = null; # Shows an underline on the first line of the scope
      showExactScope = true; # Shows an underline on the first line of the scope starting at the exact start of the scope
    };
    whitespace = {
      highlight = null; # use default |hl-IblWhitespace|
      removeBlanklineTrail = true; # set false?
    };
  };

};

colorschemes.gruvbox = {
  enable = true;
  transparentBg = true;
  trueColor = true;
  undercurl = true;
  underline = true;
  bold = true;
  improvedStrings = true;
  improvedWarnings = true;
  invertSelection = true;
};

extraPlugins = with pkgs.vimPlugins; [
      # LSP
      #{
      #  plugin = nvim-lspconfig;
      #  config = toLuaFile ../extraConfig/nvim/plugin/lsp.lua;
      #}

      # FIXME: y u no worky? >:(
      # lsp-status-nvim # FIXME: What about lspinfo?
      # lazy-lsp-nvim # FIXME: LEARN MORE
      # asyncomplete-lsp-vim # FIXME: Learn more
      #{
      #  plugin = nvim-cmp;
      #  config = toLuaFile ./plugin/cmp.lua;
      #}
      # cmp-nvim-lsp # FIXME: Learn more
      # cmp-nvim-lsp-document-symbol 
      # cmp-nvim-lsp-signature-help

      {
        plugin = comment-nvim;
        config = toLua "require(\"Comment\").setup()";
      }

      # {
      #   plugin = vim-startify;
      #   config = "let g:startify_change_to_vcs_root = 0";
      # }

      {
        plugin = nvim-colorizer-lua; # relies on AutoCmd
        config = ''
        packadd! nvim-colorizer.lua
        lua require 'colorizer'.setup()
        '';
      }

      {
        plugin = telescope-nvim;
        config = toLuaFile ./plugin/telescope.lua;
      }

      # File Tree
      # {
      #   plugin = nvim-tree-lua;
      #   config = toLuaFile ./plugin/nvim-tree.lua;
      # }
      # nvim-web-devicons # optional, for file icons

      # Code Snippits
      luasnip # FIXME: Do I need this too? NEEDED
      cmp-nvim-lsp # FIXME: What's this? NEEDED
      friendly-snippets 
      cmp_luasnip # completion for lua snippits

      {
        plugin = pkgs.vimPlugins.cmp-nvim-tags;
        config = toLuaFile ./plugin/cmp-tags.lua;
      }
      #
      # {
      #   plugin = statuscol-nvim;
      #   config = toLuaFile ./plugin/statuscol.lua;
      # }

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
      telescope-fzf-native-nvim # FIXME: How do I use?

      # Syntax Highlighting
      vim-nix # better highlighting for nix files

      # Emacs Org for nvim
      {
        plugin = neorg;
        config = toLuaFile ./plugin/neorg.lua;
      }
      neorg-telescope

      {
        plugin = guess-indent-nvim;
        config = toLua "require(\"guess-indent\").setup()";
      }

      # Git Visual integration #FIXME: USING GITGUTTER!
      # {
      #   plugin = gitsigns-nvim;
      #   config = toLuaFile ./plugin/gitsigns.lua;
      # }

      # { 
      #   plugin = lsp_lines-nvim;
      #   config = toLua ''
      #   require("lsp_lines").setup()
      #   vim.diagnostic.config({
      #     virtual_text = false,
      #   })
      #   vim.keymap.set(
      #     "",
      #     "<Leader>l",
      #     require("lsp_lines").toggle,
      #     { desc = "Toggle lsp_lines" }
      #     )
      #     '';        
      #   }
      
      # { 
      #   plugin = lualine-lsp-progress;
      #   config = toLuaFile ./plugin/lualine-lsp-progress.lua;
      # }

      {
        plugin = (nvim-treesitter.withPlugins (p: [
          p.tree-sitter-nix
          p.tree-sitter-vim
          p.tree-sitter-bash
          p.tree-sitter-lua
          p.tree-sitter-python
          p.tree-sitter-json
          p.tree-sitter-java
          p.tree-sitter-kotlin
          p.tree-sitter-javascript
          p.tree-sitter-typescript
          p.tree-sitter-swift
          p.tree-sitter-cpp
          p.tree-sitter-c
          p.tree-sitter-objc
          p.tree-sitter-c-sharp
          p.tree-sitter-rust
          p.tree-sitter-go
          p.tree-sitter-sql
          p.tree-sitter-xml
          p.tree-sitter-html
          p.tree-sitter-css
          p.tree-sitter-php
          p.tree-sitter-norg
          p.tree-sitter-ini
        ]));
        config = toLuaFile ./plugin/treesitter.lua;
      }
    ];
  };
}
