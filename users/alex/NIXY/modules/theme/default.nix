{
  nix-colors,
  config,
  pkgs,
  ...
}:
# Configure GTK, QT themes, color schemes.. USE NIXOS MODULE
let
  inherit (nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
in {
  home = {
    packages = with pkgs; [
      # note the hiPrio which makes this script more important than others and is usually used in nix to resolve name conflicts
      (pkgs.hiPrio (
        pkgs.writeShellApplication {
          name = "toggle-theme";
          runtimeInputs = with pkgs; [
            home-manager
            coreutils
            ripgrep
          ];
          # the interesting part about the script below is that we go back two generations
          # since every time we invoke an activation script home-manager creates a new generation
          text = ''
            "$(home-manager generations | head -2 | tail -1 | rg -o '/[^ ]*')"/activate
          '';
        }
      ))
    ];
  };

  gtk = {
    enable = true;
  };
  qt = {
    enable = false;
    platformTheme = "gtk";
    # name of gtk theme
    style = {
    };
  };
}
