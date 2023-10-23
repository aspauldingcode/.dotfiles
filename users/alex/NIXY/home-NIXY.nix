{ lib, config, pkgs, ... }: 

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
    file = { # MANAGE DOTFILES?
  };


};
programs = {
        home-manager.enable = true; 
      };
}
