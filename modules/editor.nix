{ inputs, ... }: {
  # This is a Home Manager module
  options.programs.neovim.initLua = inputs.nixpkgs.lib.mkOption {
    type = inputs.nixpkgs.lib.types.lines;
    default = "";
  };
}
