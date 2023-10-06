{ lib, config, pkgs, ... }:

# UNIVERSAL packages
{
  home.packages = with pkgs; [
      calcurse
      delta
      gnupg
      audacity
      pinentry
      #beeper
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
