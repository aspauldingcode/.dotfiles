{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # Define hostname once for this system
  hostname = "NIXSTATION64";
in {
  imports = [
    ./hardware-configuration
    ./scripts
    ./modules
    ./configuration
  ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}
