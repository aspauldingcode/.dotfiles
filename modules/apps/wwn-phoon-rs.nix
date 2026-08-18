# Host-native `phoon` CLI from github:Wawona/wwn-phoon-rs.
# Clean-room Rust moon-phase utility (ASCII art); same binary Wawona
# embeds in-process as libphoon_rs.a.
#
# Resolve from the flake input (not `pkgs.phoon`) so standalone HM and
# hosts without overlays.default still get the same binary.
{ inputs, ... }:
{
  flake.modules.homeManager.dendritic =
    { pkgs, ... }:
    let
      wwnPhoon = inputs.wwn-phoon-rs.packages.${pkgs.stdenv.hostPlatform.system};
      # Prefer the OS-specific output. A generic `phoon` attr may be the
      # Darwin binary on every system (meta.badPlatforms = aarch64-linux).
      phoon =
        if pkgs.stdenv.hostPlatform.isDarwin then
          wwnPhoon.phoon-macos or wwnPhoon.phoon
        else
          wwnPhoon.phoon-linux or wwnPhoon.phoon;
    in
    {
      home.packages = [ phoon ];
    };
}
