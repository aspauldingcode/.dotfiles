{ config, pkgs, nixvim, ... }: 

{
  imports = [
    # For home-manager
    nixvim.homeManagerModules.nixvim
    # For NixOS
    # nixvim.nixosModules.nixvim
    # For nix-darwin
    # nixvim.nixDarwinModules.nixvim
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
      ${builtins.readFile ../extraConfig/nvim/options.lua}
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
      lightline.enable=false;
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

	lsp = {
		enable = true;
		servers = { # https://nix-community.github.io/nixvim/plugins/lsp/
			# javascript / typescript
			tsserver.enable = true;
			# lua
			lua-ls.enable = true;
			# nix
			nil_ls = {
				enable = true;
				installLanguageServer = true;
			};# rust
			rust-analyzer = {
				enable = true;
				installCargo = true;
				installRustc = true;
			};
			# python
			pyright.enable = true; 
			/*
			lsp - pyright
			linter - flake8
			formatter - black
			*/
			# java
			# java-language-server = {
			# 	enable = true;
			# 	package = pkgs.jdt-language-server;
			# 	installLanguageServer = true;
			# 	cmd = [ "/nix/store/4qlb19k5fi0qnx5j6zk4gcycpn808pma-jdt-language-server-1.26.0/bin/jdt-language-server" 
			# 	];
			# 	#rootDir = "~/Desktop/codingProjects/java/";
			# };
		};
	};
    };
    colorschemes.gruvbox = {
      enable = true;
      #background = white;
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
        {
          plugin = nvim-cmp;
          config = toLuaFile ../extraConfig/nvim/plugin/cmp.lua;
        }
        # cmp-nvim-lsp # FIXME: Learn more
        # cmp-nvim-lsp-document-symbol 
        # cmp-nvim-lsp-signature-help

        {
          plugin = comment-nvim;
          config = toLua "require(\"Comment\").setup()";
        }

        {
          plugin = vim-startify;
          config = "let g:startify_change_to_vcs_root = 0";
        }

        {
          plugin = nvim-colorizer-lua; # relies on AutoCmd
          config = ''
          packadd! nvim-colorizer.lua
          lua require 'colorizer'.setup()
          '';
        }

        {
          plugin = telescope-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/telescope.lua;
        }

        # File Tree
        {
          plugin = nvim-tree-lua;
          config = toLuaFile ../extraConfig/nvim/plugin/nvim-tree.lua;
        }
        nvim-web-devicons # optional, for file icons

        # Code Snippits
        luasnip # FIXME: Do I need this too? NEEDED
        cmp-nvim-lsp # FIXME: What's this? NEEDED
        friendly-snippets 
        cmp_luasnip # completion for lua snippits

        {
          plugin = pkgs.vimPlugins.cmp-nvim-tags;
          config = toLuaFile ../extraConfig/nvim/plugin/cmp-tags.lua;
        }

        {
          plugin = statuscol-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/statuscol.lua;
        }

        # Visual Fixes
        {
          plugin = feline-nvim;
          config = let inherit (config.colorscheme) colors; in
          toLuaFile ../extraConfig/nvim/plugin/feline.lua;
        }

        {
          plugin = winbar-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/winbar.lua;
        }

        {
          plugin = indent-blankline-nvim; # lines to identify codeblocks
          config = toLuaFile ../extraConfig/nvim/plugin/indent-blankline.lua;
        }
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
          config = toLuaFile ../extraConfig/nvim/plugin/neorg.lua;
        }
        neorg-telescope

        {
          plugin = guess-indent-nvim;
          config = toLua "require(\"guess-indent\").setup()";
        }

        # Git Visual integration
        {
          plugin = gitsigns-nvim;
          config = toLuaFile ../extraConfig/nvim/plugin/gitsigns.lua;
        }

        #{ 
	#	plugin = gruvbox-nvim;
       # 	config = ''
	#		colorscheme gruvbox
	#	'';
      	#}

      { 
        plugin = lsp_lines-nvim;
        config = toLua ''
        require("lsp_lines").setup()
        vim.diagnostic.config({
          virtual_text = false,
        })
        vim.keymap.set(
          "",
          "<Leader>l",
          require("lsp_lines").toggle,
          { desc = "Toggle lsp_lines" }
          )
          '';        
        }

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
          ]));
          config = toLuaFile ../extraConfig/nvim/plugin/treesitter.lua;
        }
      ];
  };
}

