{
  flake.modules.homeManager.dendritic =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fastfetch ];
    };
}
