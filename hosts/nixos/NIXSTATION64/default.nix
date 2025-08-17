{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration
    ./scripts
    ./modules
    ./configuration
  ];
}
