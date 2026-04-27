{
  flake.modules.homeManager.apps = { pkgs, ... }: let
    universal = with pkgs; [
      # IDEs
      jetbrains.clion
      jetbrains.idea
      jetbrains.rider
      # Browsers
      firefox
      brave
      # Dev tools
      gh                  # GitHub CLI
      ghidra              # Reverse engineering
      jdk21               # Java development
      # System
      fastfetch           # System info
    ];

    linuxSpecific = with pkgs; [
      antigravity-fhs
      code-cursor-fhs
    ];

    darwinSpecific = with pkgs; [
      antigravity
      code-cursor
    ];
  in {
    home.packages = universal ++ (if pkgs.stdenv.isLinux then linuxSpecific else darwinSpecific);
  };
}
