{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # treesitter conf
    treesitter = {
      enable = true;
      nixvimInjections = true;
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

    # better nix highlighting with vim-nix
    nix.enable = true;
  };
}
