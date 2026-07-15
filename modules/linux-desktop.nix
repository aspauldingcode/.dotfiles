{
  # Shared Linux desktop stack (audio/print/NM) + optional sway.
  # Niri hosts enable this for pipewire/printing/NM; sway stays opt-in.
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.linux-desktop;
    in
    {
      options.dendritic.apps.linux-desktop = {
        enable = lib.mkEnableOption "shared Linux desktop stack (NetworkManager, pipewire, printing)";
        sway.enable = lib.mkEnableOption "swayfx desktop session (not used with niri)";
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          networking.networkmanager = {
            enable = lib.mkDefault true;
            wifi.backend = "iwd";
          };
          networking.wireless.enable = lib.mkDefault false;
          networking.wireless.iwd.enable = true;

          # Font rasterization (FreeType via fontconfig) — not the compositor.
          # macOS Mojave+: grayscale AA (not RGB subpixel) + slight hinting.
          # Stem-darkening via FREETYPE_PROPERTIES thickens LoDPI stems.
          # Electron/Chrome/Ghostty may partially ignore these.
          fonts.fontconfig = {
            enable = true;
            antialias = true;
            hinting = {
              enable = true;
              style = "slight";
              autohint = false; # prefer TrueType bytecode when present
            };
            subpixel = {
              rgba = "none";
              lcdfilter = "none";
            };
          };

          # Match macOS-ish stem weight on FreeType (CFF + autofitter).
          environment.sessionVariables.FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";

          environment.systemPackages = with pkgs; [
            networkmanagerapplet # nm-connection-editor (waybar network on-click)
          ];

          services.printing.enable = true;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86;
            pulse.enable = true;
          };

          services.openssh.enable = lib.mkDefault true;
          networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
        })

        (lib.mkIf (cfg.enable && cfg.sway.enable) {
          programs.sway = {
            enable = true;
            package = pkgs.swayfx;
            extraPackages = with pkgs; [
              swayidle
              wl-clipboard
              mako
              alacritty
              dmenu
            ];
          };
        })
      ];
    };
}
