# Steam — Proton-GE + NVIDIA PRIME offload on hybrid laptops.
#
# sliceanddice: Intel panel, RTX 3050 Ti via PRIME. The Steam client and its
# Proton children must offload or NVAPI/DLSS never see the dGPU. Do not enable
# a gamescope session: nested gamescope-wl ABRTs niri (see heroic.nix).
{
  flake.modules.nixos.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.steam;
      nvidia = config.hardware.nvidia.modesetting.enable or false;
      offload = config.hardware.nvidia.prime.offload.enable or false;
      # Same NVAPI/DLSS keys Heroic merges for Proton-GE. PRIME vars match
      # nvidia-offload so the client and games inherit the dGPU.
      extraEnv =
        lib.optionalAttrs nvidia {
          PROTON_ENABLE_NVAPI = "1";
          PROTON_HIDE_NVIDIA_GPU = "0";
          DXVK_ENABLE_NVAPI = "1";
          PROTON_DLSS_UPGRADE = "1";
        }
        // lib.optionalAttrs offload {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          # 610.57 still enumerates the iGPU with NVIDIA_only. DXVK games
          # need the name filter or they can render on Intel.
          __VK_LAYER_NV_optimus = "NVIDIA_only";
          DXVK_FILTER_DEVICE_NAME = "NVIDIA";
        };
    in
    {
      options.dendritic.apps.steam = {
        enable = lib.mkEnableOption ''
          Steam, with Proton-GE and NVIDIA PRIME/NVAPI when that GPU is configured.
        '';
      };

      config = lib.mkIf cfg.enable {
        programs.steam = {
          enable = true;
          # Wayland (niri): Steam Input needs X11 events translated to uinput.
          extest.enable = config.dendritic.apps.niri.enable or false;
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
          extraPackages = lib.optionals config.programs.gamemode.enable [ pkgs.gamemode ];
          package = pkgs.steam.override { inherit extraEnv; };
        };
      };
    };
}
