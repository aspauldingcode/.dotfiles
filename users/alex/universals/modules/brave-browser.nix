{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
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
        id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; # Privacy Badger
      }
      {
        id = "dhdgffkkebhmkfjojejmpbldmpobfkfo"; # Tampermonkey
      }
      {
        id = "gebbhagfogifgggkldgodflihgfeippi"; # Return YouTube Dislikes
      }
      {
        id = "hipekcciheckooncpjeljhnekcoolahp"; # Enhancer for YouTube
      }
      {
        id = "mnjggcdmjocbbbhaepdhchncahnbgone"; # SponsorBlock
      }
      {
        id = "njdfdhgcmkocbgbhcioffdbicglldapd"; # LocalCDN (similar to Privacy Badger)
      }
      {
        id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; # Dark Reader
      }
      {
        id = "iaiomicjabeggjcfkbimgmglanimpnae"; # Tab Manager Plus
      }
      {
        id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; # Decentraleyes
      }
      {
        id = "fihnjjcciajhdojfnbdddfaoknhalnja"; # I still don't care about cookies
      }
      {
        id = "noaijdpnepcgjemiklgfkcfbkokogabh"; # Clear URLs
      }
      {
        id = "mnjfcmpnjpjgkpklkafaicpipahihpgl"; # Hover Zoom+
      }
      {
        id = "ophjlpahpchlmihnnnihgmmeilfjmjjc"; # Vercel
      }
    ];
  };
}
