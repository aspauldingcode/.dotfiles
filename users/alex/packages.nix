{ inputs, lib, config, pkgs, specialArgs, ... }:

{
  home = if !pkgs.stdenv.isDarwin then {
    pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 22;
    };
    packages = with pkgs; [
      # Add your Linux-specific packages here
      # Examples: things that ONLY work in Linux
    ];
  } else if pkgs.stdenv.isDarwin then {
    packages = with pkgs; [
      # Add your macOS-specific packages here
      # Examples: things that don't work in Linux
    ];
  } else {
    # Everything else
    packages = with pkgs; [
      # Add packages that are compatible with both macOS and Linux here
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
    ];
  };
}

