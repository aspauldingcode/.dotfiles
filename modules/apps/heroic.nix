# Heroic Games Launcher — Proton-GE + DLSS/NVAPI on hybrid NVIDIA laptops.
#
# SLICEANDDICE: MSI Sword 15 A11UD, Intel Tiger Lake + RTX 3050 Ti Laptop
# (GA107 Ampere, 4 GiB). Panel is Intel; games must PRIME-offload onto NVIDIA
# or NVAPI/DLSS never see the dGPU. Ampere does DLSS 2 Super Resolution only —
# no Frame Generation. 4 GiB: Quality/Balanced at 1080p; Ultra Performance is
# muddy.
#
# Rocket League (Epic `Sugar`) has no in-game DLSS. Do NOT wrap it with
# gamescope on niri: nested gamescope-wl ABRTs the compositor (status=6).
# Scale via TASystemSettings ResX/ResY + ScreenPercentage; keep PRIME.
#
# Heroic rewrites ~/.config/heroic/config.json. Merge keys only — never
# home.file force-replace. Leave Heroic's own GE-Proton tree in place;
# proton-ge-bin is Steam-compat only.
{
  flake.modules.nixos.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.heroic;
    in
    {
      options.dendritic.apps.heroic = {
        enable = lib.mkEnableOption ''
          Heroic + GameMode, with Proton-GE DLSS/NVAPI + PRIME defaults.
        '';
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.heroic ];

        programs.gamemode = {
          enable = true;
          enableRenice = true;
        };

        users.groups.gamemode.members = lib.mkIf (config.dendritic.identity.enable or false) [
          config.dendritic.identity.username
        ];
      };
    };

  flake.modules.homeManager.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.heroic;
      heroicHome = "${config.xdg.configHome}/heroic";
      protonBin = "${heroicHome}/tools/proton/GE-Proton-latest/proton";
      merge = pkgs.writeShellApplication {
        name = "dendritic-heroic-dlss";
        runtimeInputs = [
          pkgs.python3
          pkgs.coreutils
        ];
        text = ''
          exec ${pkgs.python3}/bin/python3 ${../../scripts/dendritic-heroic-dlss.py} "$@"
        '';
      };
    in
    {
      options.dendritic.apps.heroic = {
        enable = lib.mkEnableOption ''
          Merge Heroic Proton-GE DLSS/NVAPI + PRIME settings on activation.
        '';
      };

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
        home.packages = [ merge ];

        home.activation.heroicDlss = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${lib.getExe merge} \
            --config ${lib.escapeShellArg "${heroicHome}/config.json"} \
            --store-config ${lib.escapeShellArg "${heroicHome}/store/config.json"} \
            --game-config ${lib.escapeShellArg "${heroicHome}/GamesConfig/Sugar.json"} \
            --game-key Sugar \
            --proton ${lib.escapeShellArg protonBin} \
            --strip-gamescope \
            || echo "heroic: DLSS merge skipped/failed" >&2
        '';
      };
    };
}
