# Alex's Home Manager Configuration for NIXY
# aarch64 Darwin (Apple Silicon) macOS System
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

  # macOS-specific overrides
  home.sessionVariables = {
    FLAKE = "/Users/${user}/.dotfiles";
  };

  # macOS-specific packages
  home.packages = with pkgs; [
    # macOS development tools
    darwin.lsusb

    # Cross-platform tools that work well on macOS
    vscode

    # Media tools
    # (some packages may be different or unavailable on macOS)
  ];

  # macOS-specific program configurations
  programs = {
    # Override terminal for macOS
    alacritty.settings.window.decorations = "buttonless";
  };
}
