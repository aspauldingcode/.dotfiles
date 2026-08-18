# Host-native `phoon` CLI from github:Wawona/wwn-phoon-rs.
# Clean-room Rust moon-phase utility (ASCII art); same binary Wawona
# embeds in-process as libphoon_rs.a.
{
  flake.modules.homeManager.dendritic =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.phoon ];
    };
}
