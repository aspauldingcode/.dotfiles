{
  flake.modules.homeManager.apps = { pkgs, ... }: {
    home.packages = with pkgs; [
      jetbrains.clion
      jetbrains.idea
      jetbrains.rider
      firefox
      brave
    ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      code-cursor-fhs
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      code-cursor
    ];
  };
}
