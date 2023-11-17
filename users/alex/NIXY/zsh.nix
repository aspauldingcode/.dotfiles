{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
    };
    oh-my-zsh = {
      enable = false;
      plugins = [ "git" "thefuck" ];
      theme = "robbyrussell";
    };
  };
}
