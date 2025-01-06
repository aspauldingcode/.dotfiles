{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.chromium = {
    enable = true;
    # package = pkgs.brave;
    commandLineArgs = [
      # Add any command line arguments here
      "--enable-features=UseOzonePlatform"
      (lib.optionals pkgs.stdenv.isLinux [ "--ozone-platform=wayland" ])
    ];
    dictionaries = [
      # Add dictionaries packages here if needed
    ];
    extensions = [
      {
        id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; # uBlock Origin
      }
      {
        id = "nngceckbapebfimnlniiiahkandclblb"; # Bitwarden
      }
      {
        id = "gcbommkclmclpchllfjekcdonpmejbdp"; # HTTPS Everywhere
      }
      {
        id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; # Privacy Badger
      }
    ];
  };
}
