{ config, pkgs, lib, inputs, ... }: 

# my universal neovim configuration with Nix Syntax using NixVim!
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  #programs.nixvim.enable = true; # Troubleshoot nvim
  nixpkgs.config.allowUnsupportedSystemPredicate = pkg:
  builtins.elem (lib.getName pkg) [
    "swiftformat" 
    "sourcekit-lsp" 
  ];

  # nixvim specific dependencies
  home.packages = with pkgs; [
    # linters:
    #pylint #python #NO SUCH FILE OR DIRECTORY?
    # python311Packages.flake8
    #ruff # python
    commitlint # git commits
    lint-staged # git stage
    sqlint # sql
    yamllint # yaml
    vim-vint # vimscript 
    #statix # nix
    #nixpkgs-lint-community #nix with treesitter
    #nix-linter # nix
    cargo-toml-lint # cargo.toml
    eslint_d # fast eslint
    api-linter # linter for apis in protocol buffers
    ls-lint # directory name linter
    #lua54Packages.luacheck # lua
    ktlint # kotlin
    rslint # ts, js
    #djlint # html
    #scss-lint # scss BROKEN??!?? 100% yeah its broken
    csslint # css
    cpplint # C++ static linter
    actionlint # github actions

    # formatters:
    #black # python uncomprimising 
    #luaformatter # lua
    rufo # ruby
    jsonfmt # json
    #nixpkgs-fmt # nix
    #nixfmt # nix opinionated
    #alejandra # nix uncompromising
    #google-java-format # java
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
    enableMan = false;
    options = {
      number = true;         # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 4;        # Tab width should be 2
    };
    #extraConfigLua = ''
    #-- Print a little welcome message when nvim is opened!
    #-- print("Hello world!")

    #-- All my configuration options for nvim:
    #${builtins.readFile ./options.lua}
    #'';
    #globals.mapleader = ","; # Sets the leader key to comma
    #keymaps = [ # https://github.com/nix-community/nixvim/tree/main#key-mappings
  #];
  plugins = { 
    #JAVALSP
    nvim-jdtls = {
      enable = true;
      data =  "${config.xdg.cacheHome}/jdtls/workspace";
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
    efmls-configs = {
      enable = true;
      setup = {
        all = { 
          #formatter = [
          #  "languagetool"
          #];
          linter = [
            "codespell"
          ];
        };
        nix = {
          formatter = [ "alejandra" ]; 
          linter =   [ "statix" ];
        };
        java = { 
          formatter = [ "google_java_format" ];
          #linter =   [ "" ]; 
        };
        python = {
          formatter = [ "black" ];
          linter =    [ "flake8" ];
        };
        markdown = {
          formatter = [ "mdformat" ];
          #linter =   [];
        };
        lua = {
          formatter = ["lua_format"];
          #linter =   [];
        };
        bash = {
          formatter = [ "beautysh" ];
          linter = [ "bashate" ];
        };
      };
    };
    notify = {
      enable = true;
      #stages = "slide";
    };
    gitsigns.enable = true;
    lsp = {
      enable = true;
      servers = { # https://nix-community.github.io/nixvim/plugins/lsp/
      # ansiblels = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # astro = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      bashls = {
        enable = true;
        # installLanguageServer = true;
      };
      # beancount = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      biome = {
        enable = true;
        # installLanguageServer = true;
      };
      ccls = {
        enable = true;
        # installLanguageServer = true;
      };
      clangd = {
        enable = true;
        # installLanguageServer = true;
      };
      clojure-lsp = {
        enable = true;
        # installLanguageServer = true;
      };
      cmake = {
        enable = true;
        # installLanguageServer = true;
      };
      csharp-ls = {
        enable = true;
        # installLanguageServer = false; # NOT AVAILABLE on DARWIN
      };
      cssls = {
        enable = true;
        # installLanguageServer = true;
      };
      # dagger = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      dartls = {
        enable = true;
        # installLanguageServer = true;
      };
      # denols = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # dhall-lsp-server = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # digestif = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      dockerls = {
        enable = true;
        # installLanguageServer = true;
      };
      # efm = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # elixirls = {
      #enable = true;
      #   installLanguageServer = true;
      # };
      # elmls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # emmet_ls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      eslint = {
        enable = true;
        # installLanguageServer = true;
      };
      fsautocomplete = {
        enable = true;
        # installLanguageServer = false; # DOESN'T COMPILE ON DARWIN
      };
      # futhark-lsp = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      gdscript = {
        enable = true;
        # installLanguageServer = true;
      };
      gleam = {
        enable = true;
        # installLanguageServer = true;
      };
      gopls = {
        enable = true;
        # installLanguageServer = true;
      };
      graphql = {
        enable = true;
        # installLanguageServer = true;
      };
      hls = {
        enable = true;
        # installLanguageServer = true;
      };
      html = {
        enable = false;
        # installLanguageServer = false;
      };
      #htmx = {
      #  enable = false;
      #  plugins.lsp.servers.htmx.package = ./htmx-lsp-derivation.nix;
      #  installLanguageServer = false; # FAILED
      #};
      intelephense = {
        enable = true;
        # installLanguageServer = true;
      };
      #java-language-server = { #USING JDTLS!
      #  enable = true;
      #  installLanguageServer = true;
      #};
      jsonls = {
        enable = true;
        # installLanguageServer = true;
      };
      julials = {
        enable = true;
        # installLanguageServer = true;
      };
      kotlin-language-server = {
        enable = true;
        # installLanguageServer = true;
      };
      # leanls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      ltex = {
        enable = true;
        # installLanguageServer = true;
      };
      lua-ls = {
        enable = true;
        # installLanguageServer = true;
      };
      # marksman = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # metals = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      nil_ls = {
        enable = true;
        # installLanguageServer = true;
      };
      # nixd = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # nushell = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # ols = {
      #   enable = true;
      #   installLanguageServer = false; #FAILED
      # };
      # omnisharp = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # perlpls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # pest_ls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # phpactor = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # prismals = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # prolog-ls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # pylsp = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # pylyzer = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      pyright = {
        enable = true;
        # installLanguageServer = true;
        #lsp - pyright
        #linter - flake8
        #formatter - black
      };
      #rnix-lsp = {
      #  enable = false; # using nil_ls instead!
      #  installLanguageServer = true;
      #};
      #ruff-lsp = {
      #  enable = true;
      #  installLanguageServer = true;
      #};
      rust-analyzer = {
        enable = true;
        # installLanguageServer = true;
        installCargo = true;
        installRustc = true;
      };
      # solargraph = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      sourcekit = {
        enable = true;
        # installLanguageServer = false; # FAILED TO COMPILE ON NIXOS
      };
      svelte = {
        enable = true;
        # installLanguageServer = true;
      };
      tailwindcss = {
        enable = true;
        # installLanguageServer = true;
      };
      # taplo = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # templ = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # terraformls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # texlab = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      tsserver = {
        enable = true;
        # installLanguageServer = true;
      };
      # typst-lsp = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # vls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # volar = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      vuels = {
        enable = true;
        # installLanguageServer = true;
      };
      # yamlls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
      # zls = {
      #   enable = true;
      #   installLanguageServer = true;
      # };
    };
  };
  lsp-lines.enable = true;
  lspkind.enable = true;

    # treesitter conf
    treesitter = {
      enable = true;
      folding = false; # enable by keybind?
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
      maxLines = 3; # limit to not hog up screenspace.
    };

    #wtf.enable = true; ChatGPT error explanations!

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
      keymaps = {
        
      "<C-p>" = {
        action = "git_files";
        desc = "Telescope Git Files";
      };
      "<leader>fg" = "live_grep";
      };
    };

    # code-completion
    # cmp-nvim-lua.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-nvim-lsp-signature-help.enable = true;
    cmp-zsh.enable = true;
    intellitab.enable = true;

    # AI code-completion tools
    codeium-nvim.enable = false;
    #copilot-cmp.enable = true;
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
    #lualine = {
    #  enable=true;
    #  # sections.lualine_c = [ "lsp_progress" ]; # Install lsp_progress!
    #};

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
            header = ["   MRU"];
          }
          {
            type = "dir";
            header = [{__raw = "'   MRU' .. vim.loop.cwd()";}];
          }
          {
            type = "sessions";
            header = ["   Sessions"];
          }
          {
            type = "bookmarks";
            header = ["   Bookmarks"];
          }
          {
            type = "commands";
            header = ["   Commands"];
          }
        ];
      };
    };
    #commenting
    comment-nvim.enable = true;

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
      char = "▏"; 
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

  #Note-taking
  obsidian = {
    enable = false; # Cross that bridge when we get there...
    extraOptions = {
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
    "core.defaults" = { # Load all the default modules
        #__empty = null;
      };
      "core.concealer" = { # Allows for the use of icons
    };
    "core.dirman" = { # idk what this does 
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
  customColorScheme = let inherit (config.colorScheme) colors; in { # use nix-colors
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
  #useTruecolor = true;
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
