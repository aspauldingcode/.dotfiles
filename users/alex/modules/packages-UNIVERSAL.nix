{ lib, config, pkgs, ... }:

# UNIVERSAL packages
{
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
<<<<<<< HEAD
      #beeper #broken atm
=======
      #beeper
>>>>>>> origin/main
      libusbmuxd
      sshpass
      gnumake
      git-crypt
      cowsay
      # qemu?
      # docker?
      # build-tools? (python311, jdk20, etc.)
<<<<<<< HEAD
  ];
}
=======
    ];
  }
>>>>>>> origin/main
