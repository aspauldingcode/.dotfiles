{ inputs, ... }: {
  flake.modules.homeManager.qt = { lib, ... }: {
    options.qt.kvantum = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };
    options.qt.platformTheme = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };
    config = {
      qt.enable = lib.mkDefault false;
    };
  };
}
