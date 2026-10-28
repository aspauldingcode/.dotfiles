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
# Scale via TASystemSettings ResX/ResY + ScreenPercentage.
#
# nvidiaPrime does not hide the iGPU from Vulkan. On 610.57,
# __VK_LAYER_NV_optimus=NVIDIA_only still enumerates Intel UHD, and DXVK
# will render Rocket League there (0% dGPU, ~35 MiB). The merge sets
# DXVK_FILTER_DEVICE_NAME=NVIDIA, turns off Wine FSR and verboseLogs
# (WINEDEBUG=+fixme), and does not wrap Heroic games with GameMode.
# Every Heroic game gets PROTON_ENABLE_WAYLAND=1, WINE_GRAPHICS_DRIVER=wayland,
# and WINEDLLOVERRIDES=winex11.drv=d. GE-Proton would otherwise keep the X11
# driver for per-process fallback and can start Xwayland from the runtime.
# DISPLAY is cleared so a Heroic process that still inherited :0 cannot
# hand it to the game. This session does not start XWayland.
# When the Proton EAC runtime and the laptop panel are present, the merge
# also sets PROTON_EAC_RUNTIME and PROTON_WAYLAND_MONITOR=eDP-1. The EAC
# module page-faults without the runtime, and without a monitor name the
# game exclusive-fullscreens 640x480 and the Wayland surface dies.
# Nouveau/NVK is not used: DLSS and NVAPI need this open-kernel
# NVIDIA driver, and NVK's DLSS path is still experimental.
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
          Heroic, with Proton-GE DLSS/NVAPI and the NVIDIA DXVK device filter.
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
          Merge Heroic Proton-GE DLSS/NVAPI, the NVIDIA DXVK device filter,
          and the FSR / verbose-log / GameMode overrides on activation.
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
