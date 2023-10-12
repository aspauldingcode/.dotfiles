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
      #prismlauncher-unwrapped
      (prismlauncher.override {
      jdks = [ jdk8 jdk17 jdk19 ]; 
      })
      #transmission-gtk
      calcurse
      delta
      gnupg
      audacity
      pinentry
      #beeper NOT FOR aarch64-DARWIN!
      libusbmuxd
      sshpass
      gnumake
      git-crypt
      cowsay
      discord
      #checkra1n NOT FOR aarch64-DARWIN
      zoom-us
      #android-studio NOT FOR aarch64 DARWIN
      spotify-unwrapped
      jetbrains.idea-ultimate
      #qtemu # works on windows!!!
      # qemu?
      # docker?
      # build-tools? (python311, jdk20, etc.)
  ];
}
