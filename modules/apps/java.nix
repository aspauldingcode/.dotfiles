{
  # JDK 21 for general Java development (compilers, build tools, language
  # servers). JetBrains IDEs additionally wire `programs.java` from
  # `./jetbrains.nix` when that toggle is on; this module is independent so
  # `java -version` works on hosts that don't enable JetBrains.
  flake.modules.homeManager.dendritic =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jdk21 ];
    };
}
