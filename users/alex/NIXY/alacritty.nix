{ config, lib, pkgs, ... }:

{
  alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 0;
        padding.y = 10;
        opacity   = 1;
        class.instance = "Alacritty";
        class.general  = "Alacritty";
        decorations = "buttonless";
      };
    };
  };

}
