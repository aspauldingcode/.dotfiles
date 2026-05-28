{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dendritic.mobile = {
        enable = lib.mkEnableOption "Mobile/iOS automation tooling (ansible et al.)";
      };

      config = lib.mkIf config.dendritic.mobile.enable {
        home.packages = with pkgs; [
          ansible
        ];
      };
    };
}
