{ lib, config, pkgs, ... }:

{
  programs.fish = {
    enable = false;
    interactiveShellInit = ''
      set fish_greeting "you must be tired."
    '';    
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      #{ name = "grc"; src = pkgs.fishPlugins.grc.src; } #FIXME
      # Manually packaging and enable a plugin
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
    ];
    #Oh-My-Fish?   
  };
}
