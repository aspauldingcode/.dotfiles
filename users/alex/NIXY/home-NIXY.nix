{ lib, config, pkgs, ... }: 

let
  android-sdk = pkgs.android_sdk; # Replace with the actual Android SDK package name
in
  {
    imports = [
      ./packages-NIXY.nix
      ./nvim.nix
      ./alacritty.nix
      ./git.nix
      ./fish.nix
    #./yabai.nix # FIXME UGH how do I home manager this?
    #./skhd.nix
    #./modules/NIXY/spacebar.nix
    #./modules/NIXY/fish.nix
    #./modules/NIXY/sketchybar.nix
  ];
  home = {
    username = "alex";
    homeDirectory = "/Users/alex";
    stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    shellAliases = { 
      python3 = "python3.11"; 
    };
    file = { # MANAGE DOTFILES?
  # Stable SDK symlinks
  #"SDKs/Android".source = "${android-sdk}/share/android-sdk";
  "SDKs/Java/20".source = pkgs.jdk20.home;
  "SDKs/Java/17".source = pkgs.jdk17.home;
  "SDKs/Java/11".source = pkgs.jdk11.home;
  "SDKs/Java/8".source = pkgs.jdk8.home;
};


};
programs = {
  home-manager.enable = true; 
};
}
