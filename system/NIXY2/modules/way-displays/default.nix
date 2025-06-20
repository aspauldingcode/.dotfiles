{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    way-displays
  ];

  environment.etc."way-displays/cfg.yaml" = {
    source = ./cfg.yaml;
    mode = "0644";
  };
}
