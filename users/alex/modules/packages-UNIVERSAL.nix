{ lib, config, pkgs, ... }:

# UNIVERSAL packages
{
  #imports = [
    #./extraConfig/git.nix
    #./extraConfig/fish.nix
  #];
  nixpkgs = {
    config = {
      allowUnfree = true;
      #allowUnfreePredicate = (_: true); #fixed with home-manager, needs fixing for configuration.nix system.
    };
  };
  home.packages = with pkgs; [
      calcurse
      delta
      gnupg
      audacity
      pinentry
      beeper
      libusbmuxd
      sshpass
      gnumake
      git-crypt
      cowsay
      discord
      checkra1n
      zoom-us
      android-studio
      spotify-unwrapped
      jetbrains.idea-ultimate
      corefonts
      # qemu?
      # docker?
      # build-tools? (python311, jdk20, etc.)
  ];
}
