{ config, pkgs, ... }:

{
  system.activationScripts = {
    postUserActivation.text = ''
      # Activation scripts go here
    '';
  };
}
