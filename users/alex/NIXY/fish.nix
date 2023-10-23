{ lib, config, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting "you must be tired."
    '';    
    #plugins = 
    #Oh-My-Fish?
  };
}
