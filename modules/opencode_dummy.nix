{ inputs, ... }: {
  flake.modules.homeManager.opencode = { lib, ... }: {
    options.programs.opencode.tui = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };
    options.programs.opencode.themes = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };
    config = {
      programs.opencode.enable = lib.mkDefault false;
    };
  };
}
