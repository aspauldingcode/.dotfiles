{
  flake.modules.homeManager.dendritic =
    { inputs, ... }:
    {
      options.qt.kvantum = inputs.nixpkgs.lib.mkOption {
        type = inputs.nixpkgs.lib.types.attrsOf inputs.nixpkgs.lib.unspecified;
        default = { };
      };
      config = {
        qt.enable = inputs.nixpkgs.lib.mkDefault false;
      };
    };
}
