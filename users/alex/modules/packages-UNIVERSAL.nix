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
      allowUnfreePredicate = (_: true);
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
      # qemu?
      # docker?
      # build-tools? (python311, jdk20, etc.)
  ];
}
