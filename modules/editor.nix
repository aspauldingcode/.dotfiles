{
  flake.modules.homeManager.editor = { pkgs, inputs, ... }: {
    imports = [ inputs.nixvim.homeModules.nixvim ];

    programs.nixvim = {
      enable = true;
      
      # Basic configurations
      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        smartindent = true;
      };

      # Plugins
      plugins = {
        lualine.enable = true;
        treesitter.enable = true;
        
        # We can add custom plugins here. Since Codecompanion and Yazi are specifically requested:
        # We add them via extraPlugins.
      };

      extraPlugins = with pkgs.vimPlugins; [
        # You may need to package codecompanion if it's not in nixpkgs,
        # but yazi.nvim might be available or can be fetched directly.
        # Assuming they exist in pkgs.vimPlugins or using pkgs.fetchFromGitHub
        (pkgs.vimUtils.buildVimPlugin {
          pname = "codecompanion.nvim";
          version = "latest";
          src = pkgs.fetchFromGitHub {
            owner = "olimorris";
            repo = "codecompanion.nvim";
            rev = "main";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # To be replaced with actual hash or let Nix build it to get hash
          };
        })
        (pkgs.vimUtils.buildVimPlugin {
          pname = "yazi.nvim";
          version = "latest";
          src = pkgs.fetchFromGitHub {
            owner = "mikavilpas";
            repo = "yazi.nvim";
            rev = "main";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # To be replaced
          };
        })
      ];

      # Additional Lua config for initializing the agentic IDE
      extraConfigLua = ''
        -- Add basic configuration for codecompanion and yazi.nvim
        -- require("codecompanion").setup({})
        -- require("yazi").setup()
      '';
    };
  };
}
