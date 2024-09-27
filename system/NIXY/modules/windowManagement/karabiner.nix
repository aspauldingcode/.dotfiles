{ config, pkgs, ... }:

{
  services.karabiner-elements = {
    enable = true; # Whether to enable Karabiner-Elements.
  };

  # configuration for karabiner is in home-manager.
}