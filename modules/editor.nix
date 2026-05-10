{
  flake.modules.homeManager.editor = { pkgs, inputs, lib, config, ... }:
  let
    isDarwin = pkgs.stdenv.isDarwin;
  in
  {
    # REMOVED nixvim import to isolate initLua error
    # imports = [ inputs.nixvim.homeModules.nixvim ];

    sops.secrets.anthropic_api_key = {};

    # Basic Neovim without nixvim
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      # extraLuaConfig = ""; # Use extraLuaConfig, NOT initLua
    };

    home.packages = with pkgs; [
      nixfmt
      stylua
      shfmt
      ruff
    ];
  };
}
