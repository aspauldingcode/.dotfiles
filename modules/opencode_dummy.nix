{
  flake.modules.homeManager.dendritic =
    { inputs, ... }:
    {
      options.programs.opencode.tui = inputs.nixpkgs.lib.mkOption {
        type = inputs.nixpkgs.lib.types.attrsOf inputs.nixpkgs.lib.types.unspecified;
        default = { };
      };
      options.programs.opencode.themes = inputs.nixpkgs.lib.mkOption {
        type = inputs.nixpkgs.lib.types.attrsOf inputs.nixpkgs.lib.types.unspecified;
        default = { };
      };
      config = {
        programs.opencode.enable = inputs.nixpkgs.lib.mkDefault false;
      };
    };
}
