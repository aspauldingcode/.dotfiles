{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # DM for niri hosts: greetd + gtkgreet (see modules/greetd-gtk.nix).
      # gtkgreet runs under a sway kiosk; the user session is Wayland (niri).

      # NetworkManager + iwd on every NixOS host (wifi.backend = iwd).
      # Hosts may still set hostname/firewall/users; do not reintroduce
      # wpa_supplicant as the Wi-Fi backend.
      networking.networkmanager = {
        enable = lib.mkDefault true;
        wifi.backend = "iwd";
      };
      networking.wireless.enable = lib.mkDefault false;
      networking.wireless.iwd.enable = true;

      environment.systemPackages = with pkgs; [
        networkmanagerapplet # nm-connection-editor (waybar network on-click)
      ];

      programs.sway = {
        enable = true;
        package = pkgs.swayfx;
        extraPackages = with pkgs; [
          swayidle
          wl-clipboard
          mako # notification daemon
          alacritty # default terminal
          dmenu # application launcher
        ];
      };
    };

  flake.modules.homeManager.dendritic =
    { pkgs, lib, ... }:
    {
      options.dendritic.apps.linux-desktop = {
        enable = lib.mkEnableOption "Linux Desktop (Sway)";
      };
      config = {
        # Home Manager specific linux desktop config (empty for now)
      };
    };
}
