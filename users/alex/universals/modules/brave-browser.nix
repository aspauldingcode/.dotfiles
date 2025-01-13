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
        id = "ponfpcnoihfmfllpaingbgckeeldkhle"; # Enhancer for YouTube
      }
      {
        id = "mnjggcdmjocbbbhaepdhchncahnbgone"; # SponsorBlock
      }
      {
        id = "khncfooichmfjbepaaaebmommgaepoid"; # Unhook - Remove YouTube Recommended Videos
      }
      {
        id = "nalkmonnmldhpfcpdlbdpljlaajlaphh"; # PiP - Picture in Picture
      }
      {
        id = "oldceeleldhonbafppcapldpdifcinji"; # AI Grammar Checker & Paraphraser
      }
      {
        id = "hnafhkjheookmokbkpnfpmemlppjdgoi"; # Allow Right Click
      }
      {
        id = "gkkmiofalnjagdcjheckamobghglpdpm"; # YouTube Windowed FullScreen
      }
      {
        id = "phmcfcbljjdlomoipaffekhgfnpndbef"; # Hide YouTube Thumbnails
      }
      {
        id = "lckanjgmijmafbedllaakclkaicjfmnk"; # ClearURLs
      }
      {
        id = "ephjcajbkgplkjmelpglennepbpmdpjg"; # ff2mpv
      }
      {
        id = "njdfdhgcmkocbgbhcioffdbicglldapd"; # LocalCDN (similar to Privacy Badger)
      }
      {
        id = "iplffkdpngmdjhlpjmppncnlhomiipha"; # Unpaywall
      }
      {
        id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; # Dark Reader
      }
      {
        id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; # Decentraleyes
      }
      {
        id = "edibdbjcniadpccecjdfdjjppcpchdlm"; # I still don't care about cookies
      }
      {
        id = "lckanjgmijmafbedllaakclkaicjfmnk"; # ClearURLs
      }
      {
        id = "pccckmaobkjjboncdfnnofkonhgpceea"; # Hover Zoom+
      }
      {
        id = "lahhiofdgnbcgmemekkmjnpifojdaelb"; # Vercel
      }
      {
        id = "dlnejlppicbjfcfcedcflplfjajinajd"; # Bonjourr - Minimalist startpage
      }
    ];
  };
}
