{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      ifstat = "ifstat-legacy";
    };
    oh-my-zsh = {
      enable = false;
      plugins = [ "git" "thefuck" ];
      theme = "robbyrussell";
    };
  };
}
