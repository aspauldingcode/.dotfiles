# Mac App Store — upstream nix-darwin `programs.mas` (PR #1668).
#
# Stable channel still lacks the module + activation hook; we import the
# module from `inputs.nix-darwin-unstable` (master) and bridge
# `system.activationScripts.mas` into `extraActivation` so it runs on
# nix-darwin-26.05. Package comes from nixpkgs-unstable via overlay
# (`pkgs.mas` → 7.x).
#
# Host usage:
#   programs.mas.enable = true;
#   programs.mas.packages = {
#     Xcode = 497799835;
#     "uBlock Origin Lite" = 6745342698;
#   };
{
  inputs,
  ...
}:
{
  flake.modules.darwin.dendritic =
    {
      lib,
      config,
      ...
    }:
    {
      imports = [
        "${inputs.nix-darwin-unstable}/modules/programs/mas.nix"
      ];

      # 26.05 activation order has no `mas` slot (master inserts it before
      # homebrew). Replay the script from extraActivation instead.
      config = lib.mkIf config.programs.mas.enable {
        system.activationScripts.extraActivation.text = lib.mkAfter ''
          ${config.system.activationScripts.mas.text}
        '';
      };
    };
}
