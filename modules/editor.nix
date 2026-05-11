{ inputs, ... }: {
  flake.modules.homeManager.editor = { lib, ... }: {
    options.programs.neovim.initLua = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
    config = {
      programs.neovim.enable = lib.mkDefault false;
    };
  };
}
