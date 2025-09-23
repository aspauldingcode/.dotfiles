# Alex's Home Manager Configuration for NIXY2
# aarch64 Linux (Apple Silicon) VM/Development System
{
  pkgs,
  user,
  ...
}:
let
  # Define username once for this user configuration
  username = "alex";
in
{
  imports = [
    ../../../shared/base/alex-base.nix
    ./modules
    ./home
    ./scripts
  ];

  # Pass username to all imported modules
  _module.args = {
    inherit username;
  };

  # System-specific overrides
  home.sessionVariables = {
    FLAKE = "/home/${user}/.dotfiles";
  };

  # ARM64-specific packages (some packages may not be available)
  home.packages = with pkgs; [
    # Core development tools
    vscode
    age
    sops
    fd
    gcal
    brightnessctl
    gimp
    lsof
    ncdu
    nmap
    pciutils
    ripgrep
    socat
    sshfs
    nix-search
    tigervnc
    usbmuxd
    wget
    xarchiver

    # Media (some may not be available on aarch64-linux)
    obs-studio-plugins.obs-vkcapture

    # Desktop environment tools
    bemenu
    clipman
    imv
    lxappearance
    pcmanfm

    # Development tools
    gdb
    strace

    # File management
    ranger
    yazi

    # System monitoring
    htop
    btop
    neofetch
    fastfetch
  ];

  # ARM64-specific program overrides
  programs = {
    # Some programs might need different configurations on ARM64
  };
}
