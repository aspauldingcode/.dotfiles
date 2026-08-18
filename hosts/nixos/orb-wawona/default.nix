# OrbStack NixOS guest: Wayland clients + compositors for Wawona over
# waypipe-rs ≥ 0.11. This is a *thin overlay* on OrbStack's generated
# /etc/nixos/configuration.nix — do not replace stock users, networking,
# or systemd.network. Adding `users.users.alex` is OK; deleting `_8amps`
# or rewriting systemd.network is what killed the LXC after the first
# full-flake switch.
{
  pkgs,
  lib,
  modulesPath,
  ...
}:

let
  stockNix = /etc/nixos/configuration.nix;
  hasStock = builtins.pathExists stockNix;
in
{
  imports =
    lib.optional hasStock stockNix
    ++ lib.optional (!hasStock) (
      # Darwin/CI eval only. Inside OrbStack, stockNix exists and wins.
      {
        imports = [ "${modulesPath}/virtualisation/lxc-container.nix" ];
        boot.isContainer = true;
        networking.hostName = "wawona";
        system.stateVersion = "26.05";
        users.users.alex = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "orbstack"
          ];
          uid = 1000;
        };
      }
    );

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  # waypipe-rs 0.11 (nixpkgs attribute is still `waypipe`).
  programs.niri.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    waypipe
    ghostty
    nautilus
    firefox
    brave
    weston
    niri
    sway
    hyprland
    foot
    wofi
    waybar
    gnome-shell
    gnome-console
    gnome-text-editor
    gnome-calculator
    eog
    evince
    kdePackages.plasma-workspace
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.systemsettings
    cosmic-session
    cosmic-term
    cosmic-files
    cosmic-edit
    cosmic-comp
    phosh
    phoc
    phosh-mobile-settings
    mpv
    imv
    wl-clipboard
    grim
    slurp
    wlr-randr
  ];

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # Login user is alex (Mac account is 8amps; OrbStack would default to
  # _8amps). Stock configuration.nix still owns _8amps — do not replace it.
  users.users.alex = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "orbstack"
    ];
    createHome = true;
    home = "/home/alex";
    homeMode = "700";
    useDefaultShell = true;
  };

  documentation.enable = false;
  documentation.nixos.enable = false;
}
